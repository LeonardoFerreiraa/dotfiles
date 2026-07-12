local M = {}

local CLI_ASSISTANT_BIN = vim.fn.expand('~/.local/libexec/cli-assistant/cli-assistant')

local BASE_CODESTYLE_XML = vim.fn.stdpath('config') .. '/codestyle/eclipse-profile.xml'

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

local function debug_bundles()
  local mason_registry = require('mason-registry')
  local bundles = {}

  local ok_dbg, dbg = pcall(function()
    return mason_registry.get_package('java-debug-adapter'):get_install_path()
  end)
  if ok_dbg then
    local jar = vim.fn.glob(dbg .. '/extension/server/com.microsoft.java.debug.plugin-*.jar')
    vim.list_extend(bundles, vim.split(jar, '\n', { trimempty = true }))
  end

  local ok_test, test = pcall(function()
    return mason_registry.get_package('java-test'):get_install_path()
  end)
  if ok_test then
    local jars = vim.fn.glob(test .. '/extension/server/*.jar')
    vim.list_extend(bundles, vim.split(jars, '\n', { trimempty = true }))
  end

  return bundles
end

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

  local root_markers = { '.git', 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'build.gradle.kts' }
  local root_dir = require('jdtls.setup').find_root(root_markers)
  if not root_dir or root_dir == '' then
    return
  end
  local project_name = vim.fn.fnamemodify(root_dir, ':t')
  local workspace_dir = vim.fn.stdpath('cache') .. '/jdtls-workspace/' .. project_name

  local java_home = vim.env.JAVA_HOME
  local java_bin

  if java_home and java_home ~= '' then
    java_bin = java_home .. '/bin/java'
  else
    vim.notify(
      'JAVA_HOME não definido. Rode "cli-assistant env java use <versão>" neste projeto antes de abrir o nvim.',
      vim.log.levels.WARN
    )
    java_bin = 'java'
  end

  local config = {
    cmd = {
      java_bin,
      '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      '-Dosgi.bundles.defaultStartLevel=4',
      '-Declipse.product=org.eclipse.jdt.ls.core.product',
      '-Dlog.protocol=true',
      '-Dlog.level=ALL',
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
        completion = { favoriteStaticMembers = {}, maxResults = 0 },
        format = formatter_settings(workspace_dir),
        import = { generatesMetadataFilesAtProjectRoot = false },
      },
    },
    init_options = {
      bundles = debug_bundles(),
    },
    on_attach = function()
      require('jdtls').setup_dap({ hotcodereplace = 'auto' })
      require('jdtls.dap').setup_dap_main_class_configs()
    end,
  }

  jdtls.start_or_attach(config)
end

return M
