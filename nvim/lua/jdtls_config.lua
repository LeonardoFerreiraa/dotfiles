local M = {}

local CLI_ASSISTANT_BIN = vim.fn.expand('~/.local/libexec/cli-assistant/cli-assistant')

-- Eclipse's formatter (used by jdtls) only understands its own XML profile
-- format or a project's .settings/org.eclipse.jdt.core.prefs. The base
-- codestyle (brace position, wrapping, import order, etc.) comes from a
-- full Eclipse profile checked into the dotfiles repo.
--
-- Indentation (tab vs space, size) is NOT controlled by this XML in
-- practice: the LSP textDocument/formatting request always carries
-- required FormattingOptions.tabSize/insertSpaces fields (derived by
-- Neovim from the buffer's 'shiftwidth'/'expandtab'), and jdtls prioritizes
-- those request-level values over whatever the profile XML says for the
-- equivalent tabulation.size/tabulation.char keys. So indentation is
-- handled separately, as buffer-local vim options (see
-- apply_indentation_defaults below) — the XML's own tabulation settings
-- are effectively a dead letter and not worth fighting.
local BASE_CODESTYLE_XML = vim.fn.stdpath('config') .. '/codestyle/eclipse-profile.xml'

-- Extracts { [setting_id] = value } from an Eclipse formatter profile XML.
local function parse_formatter_xml(path)
  local settings = {}
  local f = io.open(path, 'r')
  if not f then
    return settings
  end
  local content = f:read('*a')
  f:close()
  for id, value in content:gmatch('<setting%s+id="([^"]+)"%s+value="([^"]*)"%s*/>') do
    settings[id] = value
  end
  return settings
end

-- Writes the base codestyle profile to the jdtls workspace dir (cache,
-- outside the project — never versioned with it) and returns the
-- java.format settings pointing at it. Returns nil when the base codestyle
-- XML is missing, so callers fall back to jdtls's own default profile.
local function formatter_settings(workspace_dir)
  local settings = parse_formatter_xml(BASE_CODESTYLE_XML)
  if vim.tbl_isempty(settings) then
    return nil
  end

  local lines = { '<?xml version="1.0" encoding="UTF-8" standalone="no"?>', '<profiles version="1">',
    '<profile kind="CodeFormatterProfile" name="dotfiles" version="1">' }
  for id, value in pairs(settings) do
    table.insert(lines, string.format('<setting id="%s" value="%s"/>', id, value))
  end
  table.insert(lines, '</profile>')
  table.insert(lines, '</profiles>')

  vim.fn.mkdir(workspace_dir, 'p')
  local xml_path = workspace_dir .. '/formatter-profile.xml'
  vim.fn.writefile(lines, xml_path)

  return { settings = { url = xml_path, profile = 'dotfiles' } }
end

-- Sets 'shiftwidth'/'tabstop'/'expandtab' for the buffer from the base
-- codestyle's tabulation.size/tabulation.char, so the LSP format request's
-- (required) tabSize/insertSpaces fields match the project's real style
-- instead of the editor's own global default. Skipped when the buffer
-- already has a resolved .editorconfig with its own indent properties
-- (`vim.b[bufnr].editorconfig`, set by Neovim before FileType fires) —
-- that's project-specific and takes priority over the dotfiles base.
local function apply_indentation_defaults(bufnr)
  local ec = vim.b[bufnr] and vim.b[bufnr].editorconfig
  if ec and (ec.indent_style or ec.indent_size or ec.tab_width) then
    return
  end

  local settings = parse_formatter_xml(BASE_CODESTYLE_XML)
  local size = tonumber(settings['org.eclipse.jdt.core.formatter.tabulation.size'])
  local char = settings['org.eclipse.jdt.core.formatter.tabulation.char']
  if not size then
    return
  end

  vim.bo[bufnr].shiftwidth = size
  vim.bo[bufnr].tabstop = size
  vim.bo[bufnr].expandtab = char ~= 'tab'
end

-- Lists JDK versions installed via cli-assistant, e.g. { 11, 17, 21, ... }.
local function list_installed_jdks()
  if vim.fn.executable(CLI_ASSISTANT_BIN) == 0 then
    return {}
  end
  local output = vim.fn.system({ CLI_ASSISTANT_BIN, 'env', 'java', 'list' })
  local versions = {}
  for line in output:gmatch('[^\r\n]+') do
    local ok, decoded = pcall(vim.json.decode, line)
    if ok and decoded and decoded.version then
      table.insert(versions, decoded.version)
    end
  end
  return versions
end

-- Lets you pick an installed JDK (via cli-assistant) and (re)starts jdtls for
-- the current buffer using it. Useful when nvim was opened from a directory
-- that has no JDK selected in cli-assistant, so jdtls never started.
function M.pick_jdk_and_start()
  local versions = list_installed_jdks()
  if #versions == 0 then
    vim.notify('Nenhuma JDK encontrada via cli-assistant.', vim.log.levels.ERROR)
    return
  end
  local labels = vim.tbl_map(function(v)
    return tostring(v)
  end, versions)
  vim.ui.select(labels, { prompt = 'Selecione a JDK para o jdtls:' }, function(choice)
    if not choice then
      return
    end
    vim.env.JAVA_HOME = vim.fn.expand('~/.cli-assistant/jdks/' .. choice .. '/Contents/Home')
    vim.env.PATH = vim.env.JAVA_HOME .. '/bin:' .. vim.env.PATH
    M.setup()
  end)
end

-- Wipes the jdtls workspace data dir for the current project and restarts the
-- server, forcing a full re-index. Useful after switching JDKs mid-session or
-- to recover from a corrupted workspace index.
function M.reindex()
  require('jdtls.setup').wipe_data_and_restart()
end

function M.setup(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  apply_indentation_defaults(bufnr)
  local jdtls = require('jdtls')

  local mason_registry = require('mason-registry')
  local jdtls_pkg = mason_registry.get_package('jdtls')
  local jdtls_path = jdtls_pkg:get_install_path()

  local launcher_jar = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')

  local os_config
  if vim.fn.has('mac') == 1 then
    os_config = vim.fn.system('uname -m'):match('arm') and 'mac_arm' or 'mac'
  elseif vim.fn.has('unix') == 1 then
    os_config = vim.fn.system('uname -m'):match('arm') and 'linux_arm' or 'linux'
  else
    os_config = 'win'
  end

  -- workspace folder, one per project (based on project root name)
  local root_markers = { '.git', 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'build.gradle.kts' }
  local root_dir = require('jdtls.setup').find_root(root_markers)
  if not root_dir or root_dir == '' then
    return
  end
  local project_name = vim.fn.fnamemodify(root_dir, ':t')
  local workspace_dir = vim.fn.stdpath('cache') .. '/jdtls-workspace/' .. project_name

  -- JDK is managed per-project by cli-assistant (~/.cli-assistant/shims/java),
  -- which sets $JAVA_HOME based on cwd. Run jdtls with the JDK already selected
  -- for this project instead of hardcoding a JDK path.
  local java_home = vim.env.JAVA_HOME
  local java_bin

  if java_home and java_home ~= '' then
    java_bin = java_home .. '/bin/java'
  else
    vim.notify(
      'JAVA_HOME não definido. Rode "cli-assistant env java use <versão>" neste projeto antes de abrir o nvim.',
      vim.log.levels.WARN
    )
    java_bin = 'java' -- falls back to whatever is on PATH (the cli-assistant shim)
  end

  local config = {
    cmd = {
      java_bin,
      '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      '-Dosgi.bundles.defaultStartLevel=4',
      '-Declipse.product=org.eclipse.jdt.ls.core.product',
      '-Dlog.protocol=true',
      '-Dlog.level=ALL',
      -- keeps .project/.classpath/.settings out of the project root, inside
      -- the jdtls workspace dir instead (like IntelliJ's .idea). The
      -- equivalent `settings.java.import.generatesMetadataFilesAtProjectRoot`
      -- key is unreliable (redhat-developer/vscode-java#2929) — this JVM
      -- system property form is honored consistently.
      '-Djava.import.generatesMetadataFilesAtProjectRoot=false',
      '-javaagent:' .. jdtls_path .. '/lombok.jar',
      '-Xmx1g',
      '--add-modules=ALL-SYSTEM',
      '--add-opens', 'java.base/java.util=ALL-UNNAMED',
      '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
      '-jar', launcher_jar,
      '-configuration', jdtls_path .. '/config_' .. os_config,
      '-data', workspace_dir,
    },
    root_dir = root_dir,
    settings = {
      java = {
        signatureHelp = { enabled = true },
        completion = { favoriteStaticMembers = {} },
        format = formatter_settings(workspace_dir),
        import = { generatesMetadataFilesAtProjectRoot = false },
      },
    },
    init_options = {
      bundles = {},
    },
  }

  jdtls.start_or_attach(config)
end

return M
