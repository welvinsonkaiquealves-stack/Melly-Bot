// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Brazilian Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get memoryShortRetention =>
      'Memórias de curto prazo permanecem neste dispositivo sem expiração automática. Pressione uma entrada para deletá-la ou selecione várias para deletá-la.';

  @override
  String get memoryShortDeleteConfirm => 'Apagar memórias de curto prazo?';

  @override
  String get memoryShortDeleteScope =>
      'Exclui permanentemente apenas as memórias de curto prazo selecionadas e o índice de busca correspondente. O histórico de conversas, as notas rápidas originais, as memórias de longo prazo extraídas e o contexto da conversa atual são preservados.';

  @override
  String get memoryShortDeleteFailed =>
      'A eliminação não foi concluída. A lista foi atualizada. Selecione as entradas novamente e tente novamente.';

  @override
  String get memoryShortDeleted => 'Memórias de curto prazo apagadas';

  @override
  String get appName => 'Melly';

  @override
  String get brandName => 'Melly';

  @override
  String get brandNameEnglish => 'Melly';

  @override
  String get commonLoading => 'Carregando';

  @override
  String get homeDrawerSearchHint => 'Busca';

  @override
  String get homeDrawerClearSearch => 'Limpar busca';

  @override
  String get themeModeTitle => 'Tema';

  @override
  String get themeModeSubtitle =>
      'Troque entre luz, escuro ou aparência do sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSubtitle =>
      'Escolha o idioma da interface, dos prompts dos agentes e dos textos das ferramentas';

  @override
  String get languageFollowSystem => 'Seguir o sistema';

  @override
  String get languageZhHans => 'Chinês simplificado';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSectionModelMemory => 'Modelos e memória';

  @override
  String get settingsSectionServiceEnvironment => 'Serviços e ambiente';

  @override
  String get settingsSectionExperienceAppearance => 'Experiência e aparência';

  @override
  String get settingsSectionPermissionInfo => 'Permissões e informações';

  @override
  String get settingsModelProviderTitle => 'Provedores de modelos';

  @override
  String get settingsModelProviderSubtitle =>
      'Configure parâmetros de modelo, chaves de API e listas de modelos';

  @override
  String get settingsSceneModelTitle => 'Configuração de modelos por cenário';

  @override
  String get settingsSceneModelSubtitle =>
      'Ligar modelos por cena e usar o modelo padrão para cenas sem ligação';

  @override
  String get settingsWorkspaceMemoryTitle => 'Memória do espaço de trabalho';

  @override
  String get settingsWorkspaceMemoryLoading => 'Carregando...';

  @override
  String get settingsWorkspaceMemoryEnabled =>
      'Memória do espaço de trabalho ativada';

  @override
  String get settingsWorkspaceMemoryLexical =>
      'Use a memória do espaço de trabalho.';

  @override
  String get settingsMcpToolsTitle => 'Ferramentas MCP';

  @override
  String get settingsMcpToolsSubtitle =>
      'Adicionar, ativar e gerenciar serviços remotos MCP';

  @override
  String get settingsLocalServiceTitle => 'Serviço Local';

  @override
  String get settingsLocalServiceSubtitle =>
      'Acesse o MCP e o webchat da Melly pela sua rede local';

  @override
  String get settingsAlpineTitle => 'Ambiente Terminal';

  @override
  String get settingsAlpineSubtitle =>
      'Escolha e gerencie o sistema de terminais Alpino ou Ubuntu.';

  @override
  String get settingsHideRecentsTitle => 'Ocultar dos recentes';

  @override
  String get settingsHideRecentsSubtitle =>
      'Esconda o aplicativo da lista de tarefas recentes quando habilitado.';

  @override
  String get settingsRecentConversationsOnlyTitle =>
      'Mostrar apenas conversas recentes de 7 dias';

  @override
  String get settingsRecentConversationsOnlySubtitle =>
      'Arquivar automaticamente conversas não atualizadas por mais de 7 dias para acelerar a barra lateral';

  @override
  String get settingsAlarmTitle => 'Configuração do Alarme';

  @override
  String get settingsAlarmSubtitle =>
      'Configure o toque padrão, um mp3 local ou um URL mp3';

  @override
  String get settingsAppearanceTitle => 'Aparência';

  @override
  String get settingsAppearanceSubtitle =>
      'Configure o modo de tema, idioma, fundo compartilhado, tamanho da fonte do chat e cor do texto';

  @override
  String get settingsVibrationTitle => 'Feedback de vibração';

  @override
  String get settingsVibrationSubtitle =>
      'Use vibração para sinalizar o progresso da tarefa enquanto executa';

  @override
  String get settingsIndependentSendButtonTitle =>
      'Botão de Envio Independente';

  @override
  String get settingsIndependentSendButtonSubtitle =>
      'Quando habilitado, Enter cria uma nova linha; Quando desativado, Enter envia a mensagem diretamente';

  @override
  String get settingsPredictiveBackTitle => 'Gesto Preditivo de Volta';

  @override
  String get settingsPredictiveBackSubtitle =>
      'Quando ativado, o gesto atrás segue seu dedo para visualizar a página anterior ou tela inicial; Quando incapacitado, o comportamento do legado é mantido.';

  @override
  String get settingsHabitualHandTitle => 'Mão Dominante';

  @override
  String get settingsHabitualHandSubtitle =>
      'Muda a direção para menus de histórico de bate-papo';

  @override
  String get settingsHabitualHandLeft => 'Esquerda.';

  @override
  String get settingsHabitualHandRight => 'Direita';

  @override
  String get settingsAboutTitle => 'Sobre a Melly';

  @override
  String get settingsHideRecentsFailed =>
      'Não foi possível atualizar os dados.';

  @override
  String get settingsSaveFailed => 'Não conseguiu salvar as configurações.';

  @override
  String settingsMcpEnabledToast(Object endpoint) {
    return 'MCP ativado: $endpoint';
  }

  @override
  String get settingsMcpDisabledToast => 'MCP desativado';

  @override
  String get settingsMcpToggleFailed => 'Falha ao alternar MCP';

  @override
  String get settingsCopiedAddress => 'Endereço copiado';

  @override
  String get settingsCopiedToken => 'Token copiado';

  @override
  String get settingsTokenRefreshed => 'Token atualizado';

  @override
  String get settingsTokenRefreshFailed => 'Falha ao atualizar o token';

  @override
  String get settingsMcpLocalService => 'Serviço Local';

  @override
  String get settingsMcpAddress => 'Endereço';

  @override
  String get settingsMcpToken => 'Token';

  @override
  String get settingsNotGenerated => 'Não gerado.';

  @override
  String get settingsCopyAddress => 'Copiar endereço';

  @override
  String get settingsCopyToken => 'Copiar token';

  @override
  String get settingsRefreshToken => 'Atualizar token';

  @override
  String get settingsMcpSecurityNotice =>
      'Use o serviço MCP local na mesma rede com Authorization: Bearer <Token>. Não exponha o endereço nem o token à internet pública.';

  @override
  String get settingsInstalledAppsPermissionFailed =>
      'Não foi possível solicitar permissão de aplicativos instalados.';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceAutoSaving => 'Salvando mudanças...';

  @override
  String get appearanceAutosaveHint =>
      'As mudanças são salvas automaticamente.';

  @override
  String get appearanceBackgroundSource => 'Fonte de fundo';

  @override
  String get appearancePreview => 'Visualização';

  @override
  String get appearanceAdjustments => 'Ajustes';

  @override
  String get appearancePreviewChat => 'Conversa';

  @override
  String get appearancePreviewWorkspace => 'Espaço de trabalho';

  @override
  String get appearanceEnableBackground => 'Ativar imagem de fundo';

  @override
  String get appearanceEnableBackgroundSubtitle =>
      'Aplique nas páginas do Chat e do Workspace e salve automaticamente.';

  @override
  String get appearanceSourceLocal => 'Imagem Local';

  @override
  String get appearanceSourceRemote => 'URL da imagem';

  @override
  String get appearanceNoLocalImage => 'Nenhuma imagem local selecionada ainda';

  @override
  String get appearancePickImage => 'Escolha a imagem';

  @override
  String get appearanceRepickImage => 'Escolha novamente.';

  @override
  String get appearanceRemoteImageUrl => 'URL da imagem';

  @override
  String get appearanceRemoteImageUrlHint =>
      'https://exemplo.com/background.jpg';

  @override
  String get appearanceBackgroundBlur => 'Desfoque do fundo';

  @override
  String get appearanceBackgroundBlurSubtitle =>
      'Ajuste o desfoque da camada sobre a imagem';

  @override
  String get appearanceOverlayIntensity => 'Intensidade da sobreposição';

  @override
  String get appearanceOverlayIntensitySubtitle =>
      'Aumente a sobreposição unificada para tornar a UI mais limpa.';

  @override
  String get appearanceOverlayBrightness => 'Sobrepor Brilho';

  @override
  String get appearanceOverlayBrightnessSubtitle =>
      'Brilhar ou escurecer a sobreposição sem modificar a própria imagem';

  @override
  String get appearanceChatTextSize => 'Tamanho do Texto do Chat';

  @override
  String get appearanceChatTextSizeSubtitle =>
      'Só afeta as mensagens do usuário, AI responde, e o painel de pensamento';

  @override
  String get appearanceTextColorTitle => 'Cor do Texto do Chat';

  @override
  String get appearanceTextColorSubtitle =>
      'Por padrão, ele se adapta ao fundo, ou você pode fixar uma cor personalizada';

  @override
  String get appearanceTextColorAuto => 'Auto';

  @override
  String get appearanceCustomColorLabel => 'Cor Personalizada';

  @override
  String get appearanceCustomColorHint => '#FFFFFF ou #FF112233';

  @override
  String get appearancePreviewTip =>
      'Você pode arrastar a imagem e apertar para ampliar a visualização acima. A prévia fica perto do efeito real.';

  @override
  String get appearanceColorWhite => 'Branco';

  @override
  String get appearanceColorDarkGray => 'Cinza Escuro';

  @override
  String get appearanceColorLightBlue => 'Azul claro';

  @override
  String get appearanceColorNavy => 'Marinha';

  @override
  String get appearanceColorTeal => 'Teal.';

  @override
  String get appearanceColorWarmYellow => 'Amarelo Quente';

  @override
  String get appearanceInvalidHttpUrl =>
      'Digite um URL válido de imagem http(s)';

  @override
  String get appearanceInvalidHexColor => 'Digite #RRGGBB ou #AARGGBB';

  @override
  String get appearanceInvalidHexColorFormat => 'Código de cores inválido';

  @override
  String appearancePickImageFailed(Object error) {
    return 'Não consegui escolher a imagem. $error';
  }

  @override
  String get appearancePickLocalImageFirst =>
      'Selecione uma imagem local primeiro.';

  @override
  String get appearanceLocalImageMissing =>
      'A imagem local não existe mais. Por favor, escolha de novo.';

  @override
  String appearanceAutosaveFailed(Object error) {
    return 'Salvamento automático falhou. $error';
  }

  @override
  String get chatToolCalling => 'Chamando ferramenta';

  @override
  String get chatFallbackReply =>
      'Não posso gerar uma resposta agora. Por favor, tente de novo.';

  @override
  String get chatPermissionRequired =>
      'Permissões devem ser ativadas antes de executar tarefas.';

  @override
  String chatPermissionRequiredWithNames(Object names) {
    return 'Habilite essas permissões antes de executar tarefas: $names';
  }

  @override
  String get chatRecentTerminalOutputNotice =>
      '[Apenas a saída mais recente do terminal é mostrada]\n';

  @override
  String chatUserPrefix(Object text) {
    return 'Usuário: $text\n';
  }

  @override
  String get permissionOverlay => 'Sobreposição';

  @override
  String get permissionInstalledApps => 'Acesso de aplicativos instalados';

  @override
  String get permissionPublicStorage => 'Acesso ao Armazenamento Público';

  @override
  String get browserOverlayTitle => 'Agente Navegador';

  @override
  String get browserOverlayClose => 'Fechar janela do navegador';

  @override
  String get browserOverlayUnsupported =>
      'A visão da ferramenta do navegador ainda não é suportada nesta plataforma.';

  @override
  String get networkErrorMessage =>
      'Desculpe, a emissora acabou de tropeçar. Por favor, tente enviar de novo.';

  @override
  String get rateLimitErrorMessage =>
      'A Melly está ocupada agora. Tente novamente em instantes.';

  @override
  String get chatHistoryArchivedTitle => 'Conversas Arquivadas';

  @override
  String get chatHistoryTitle => 'História do Chat';

  @override
  String get chatHistoryNoArchived => 'Sem conversas arquivadas.';

  @override
  String get chatHistoryEmpty => 'Sem conversas ainda.';

  @override
  String get chatHistoryArchivedToast => 'Arquivado';

  @override
  String get chatHistoryUnarchivedToast => 'Fora do arquivo.';

  @override
  String get chatHistoryArchiveFailed => 'Não foi possível arquivar a conversa';

  @override
  String get chatHistoryUnarchiveFailed => 'Não consegui restaurar a conversa.';

  @override
  String get chatHistoryArchiveHint =>
      'Swipe saiu em uma conversa para arquivá-lo.';

  @override
  String get homeDrawerArchive => 'Arquivo';

  @override
  String get homeDrawerNewChat => 'Nova conversa';

  @override
  String get webchatNoChats => 'Comece uma nova conversa.';

  @override
  String get memoryCenterTitle => 'Centro de Memória';

  @override
  String get memoryShortTermTitle => 'Memória de curto prazo';

  @override
  String get memoryLongTermTitle => 'Memória de longo prazo';

  @override
  String get memoryNoShortTerm => 'Sem memória de curto prazo ainda.';

  @override
  String get memoryNoShortTermDesc =>
      'Informações de processos de conversas se instalam em memória de curto prazo e depois se organizam em memória de longo prazo.';

  @override
  String get memoryFilteredNoShortTerm =>
      'Sem memória de curto prazo sob filtro atual.';

  @override
  String get memoryFilteredNoShortTermDesc =>
      'Volte mais tarde, novas memórias de curto prazo aparecerão gradualmente.';

  @override
  String get memoryNoLongTerm =>
      'Memória de longo prazo ainda não inicializada';

  @override
  String get memoryNoLongTermDesc =>
      'Quando a memória estiver ativada, suas memórias de longo prazo se acumularão aqui.';

  @override
  String get memoryDeleteConfirmTitle => 'Tem certeza de que deseja excluir?';

  @override
  String get memoryDeleteWarning => 'Essa ação não pode ser desfeita.';

  @override
  String get memoryEditDisabled =>
      'Editar memória de curto prazo não é suportado.';

  @override
  String get memoryDeleteDisabled =>
      'Apagar memória de curto prazo não é suportado.';

  @override
  String get memoryGreeting => 'Olá.\nVamos manter suas memórias juntas aqui.';

  @override
  String memorySelectedCount(Object n) {
    return '$n selecionado';
  }

  @override
  String get memoryDeselectAll => 'Deseleccionar todos';

  @override
  String get memoryEditTitle => 'Editar memória';

  @override
  String get memoryIdLabel => 'ID da memória';

  @override
  String get memoryMatchScore => 'Pontuação de jogo';

  @override
  String get memoryAdditionalInfo => 'Informações adicionais';

  @override
  String get memoryAddLongTerm => 'Adicionar memória de longo prazo';

  @override
  String get memorySaveToLongTerm => 'Salvar para memória de longo prazo';

  @override
  String get memoryLongTermAdded => 'Memória de longo prazo adicionada';

  @override
  String get memoryEditLongTerm => 'Editar memória de longo prazo';

  @override
  String get memorySaveChanges => 'Salvar mudanças';

  @override
  String get memoryDeleteLongTermConfirm =>
      'Apagar essa memória de longo prazo?';

  @override
  String get memoryLongTermDeleted => 'Memória de longo prazo apagada';

  @override
  String memoryLongTermFailed(Object error) {
    return 'A operação de memória de longo prazo falhou. $error';
  }

  @override
  String get memoryNoMemories => 'Sem memórias.';

  @override
  String get memoryNoMemoriesDesc =>
      'Comece a explorar e adicionar conteúdo que você gosta.';

  @override
  String get pluginMarketTitle => 'Mercado de Plugins';

  @override
  String get pluginMarketEmpty => 'Nenhum plugin disponível';

  @override
  String get pluginMarketEmptyDesc =>
      'Plugins oficiais aparecerão aqui uma vez conectados.';

  @override
  String get pluginInstall => 'Instalar';

  @override
  String get pluginUpdate => 'Atualizar';

  @override
  String get pluginUninstall => 'Desinstalar';

  @override
  String get pluginCancel => 'Cancelar';

  @override
  String get pluginNoDescription => 'Sem descrição.';

  @override
  String get pluginIncompatible =>
      'Este plugin é incompatível com a versão atual.';

  @override
  String get pluginLoadFailed => 'Falha ao carregar o mercado de plugins';

  @override
  String get pluginInstallFailed => 'Não foi possível instalar o plugin';

  @override
  String get pluginUpdateFailed => 'Não foi possível atualizar o plugin';

  @override
  String get pluginToggleFailed => 'Não foi possível alternar o plugin';

  @override
  String get pluginUninstallFailed => 'Não foi possível desinstalar o plugin';

  @override
  String get pluginUninstallTitle => 'Desinstalar plug-in';

  @override
  String pluginUninstallConfirmMsg(Object name) {
    return 'Desinstalar "$name"?';
  }

  @override
  String pluginInstalledMsg(Object name) {
    return 'Instalado $name';
  }

  @override
  String pluginUpdatedMsg(Object name) {
    return 'Actualizado $name';
  }

  @override
  String pluginEnabledMsg(Object name) {
    return '$name ativado';
  }

  @override
  String pluginDisabledMsg(Object name) {
    return 'Deficiente. $name';
  }

  @override
  String pluginUninstalledMsg(Object name) {
    return 'Desinstalado $name';
  }

  @override
  String get pluginKindBundledModule => 'Módulo agrupado.';

  @override
  String get pluginKindRuntimeBundle => 'Pacote de corrida';

  @override
  String get pluginKindCompanionApp => 'Aplicativo de acompanhante';

  @override
  String get pluginDetailTitle => 'Detalhes do Plugin';

  @override
  String get pluginSearchHint => 'Procure plugins, descrições ou capacidades';

  @override
  String get pluginSearchEmpty => 'Sem plug-ins correspondentes.';

  @override
  String get pluginAboutTitle => 'Sobre';

  @override
  String get pluginCapabilitiesTitle => 'Capacidades';

  @override
  String get pluginNoCapabilities =>
      'Este plugin não declara nenhuma capacidade adicional.';

  @override
  String get pluginInformationTitle => 'Informação';

  @override
  String get pluginPublisherLabel => 'Desenvolvimento';

  @override
  String get pluginVersionLabel => 'Versão';

  @override
  String get pluginTypeLabel => 'Tipo';

  @override
  String get pluginDownloadSizeLabel => 'Tamanho do download';

  @override
  String get pluginInterfaceVersionLabel => 'Versão da interface';

  @override
  String get pluginStatusInstalled => 'Instalado';

  @override
  String get pluginStatusEnabled => 'Ativado';

  @override
  String get pluginStatusNotInstalled => 'Não instalado.';

  @override
  String get pluginEnableTitle => 'Ativar plugin';

  @override
  String get pluginEnableDescription =>
      'Permita que o Agente use as capacidades deste plugin.';

  @override
  String get pluginRetry => 'Tente novamente.';

  @override
  String get skillStoreTitle => 'Loja de Habilidade';

  @override
  String get skillBuiltin => 'Embutida.';

  @override
  String get skillOfficial => 'Oficial';

  @override
  String get skillUser => 'Usuário';

  @override
  String get skillInstalled => 'Instalado';

  @override
  String get skillNotInstalled => 'Não instalado.';

  @override
  String get skillEnabled => 'Ativado';

  @override
  String get skillDisabled => 'Deficiente.';

  @override
  String get skillInstall => 'Instalar';

  @override
  String get skillDelete => 'Apagar';

  @override
  String get skillEmpty => 'Nenhuma habilidade disponível.';

  @override
  String get skillNoDescription => 'Sem descrição.';

  @override
  String get skillBuiltinRemovedDesc =>
      'Essa habilidade foi removida do espaço de trabalho. Você pode reinstalá-lo a qualquer hora.';

  @override
  String get skillDeleteTitle => 'Delete Habilidade';

  @override
  String skillDeleteConfirmMsg(Object name) {
    return 'Excluir "$name"?';
  }

  @override
  String get skillDeleted => 'Excluída';

  @override
  String get skillDeleteFailed => 'Não foi possível apagar.';

  @override
  String skillInstalledMsg(Object name) {
    return 'Instalado $name';
  }

  @override
  String get skillInstallFailed => 'Não foi possível instalar';

  @override
  String skillEnabledMsg(Object name) {
    return '$name ativada';
  }

  @override
  String skillDisabledMsg(Object name) {
    return 'Deficiente. $name';
  }

  @override
  String get skillToggleFailed => 'Falha ao alterar o estado da habilidade';

  @override
  String get skillSyncOfficialTooltip =>
      'Instalar/atualizar habilidades oficiais';

  @override
  String skillSyncOfficialSuccess(Object count) {
    return 'Habilidades oficiais sincronizadas ($count)';
  }

  @override
  String get skillSyncOfficialFailed =>
      'Não conseguiu sincronizar as habilidades oficiais.';

  @override
  String get skillLoadFailed => 'Não conseguiu carregar habilidades.';

  @override
  String get modelProviderConfigTitle => 'Configuração do provedor';

  @override
  String get modelProviderConfigDesc =>
      'Adicione, troque e mantenha os nomes, endereços e chaves dos provedores de serviços.';

  @override
  String get modelProviderName => 'Nome do fornecedor';

  @override
  String get modelProviderNameHint => 'Por exemplo, DeepSeek';

  @override
  String get modelProviderBaseUrlHint =>
      'Adicionar # para desativar o caminho de solicitação auto-completo';

  @override
  String get modelProviderApiKeyHint =>
      'Os pedidos serão feitos sem autenticação quando a API Key não for preenchida.';

  @override
  String get modelListTitle => 'Lista de modelos';

  @override
  String get modelListDesc =>
      'Suporta adicionar modelos manualmente ou buscar a lista de modelos remotos do provedor atual.';

  @override
  String modelListCount(Object count) {
    return '$count Modelos no total';
  }

  @override
  String get modelAddPrompt => 'Por favor, adicione um modelo!';

  @override
  String get modelBuiltinProvider => 'Provedor integrado';

  @override
  String get modelIdEmpty =>
      'A identificação do modelo não pode estar vazia e não pode começar com \'cena\'.';

  @override
  String get modelAlreadyExists => 'O modelo já existe.';

  @override
  String get modelAdded => 'Modelo adicionado';

  @override
  String get modelDeleted => 'Modelo excluído';

  @override
  String get modelDeleteFailed => 'Não foi possível apagar o modelo.';

  @override
  String get modelIdHint => 'Digite o ID do modelo';

  @override
  String get modelAddProviderTitle => 'Adicionar provedor';

  @override
  String get modelAddButton => 'Adicionar';

  @override
  String get modelProviderAdded => 'Fornecedor adicionado';

  @override
  String modelProviderAddFailed(Object error) {
    return 'Não foi possível adicionar provedor: $error';
  }

  @override
  String get modelDeleteProviderTitle => 'Excluir provedor';

  @override
  String modelDeleteProviderMsg(Object name) {
    return 'Excluir "$name"? Os vínculos de cenário serão preservados, mas será necessário selecionar outro provedor disponível.';
  }

  @override
  String get modelProviderDeleted => 'Provedor excluído';

  @override
  String modelProviderDeleteFailed(Object error) {
    return 'Não conseguiu apagar o Provedor. $error';
  }

  @override
  String get modelProviderLoadFailed =>
      'Não foi possível carregar as configurações do fornecedor do modelo.';

  @override
  String modelProviderSwitchFailed(Object error) {
    return 'Não consegui trocar de fornecedor. $error';
  }

  @override
  String get modelProviderBaseUrlRequired => 'Digite um URL de base primeiro';

  @override
  String get modelProviderInvalidBaseUrl =>
      'Digite um URL base válido para http(s)';

  @override
  String modelProviderFetchedModels(Object count) {
    return '$count modelos encontrados';
  }

  @override
  String modelProviderFetchFailed(Object error) {
    return 'Não foi possível obter a lista de modelos: $error';
  }

  @override
  String get sceneModelMapping => 'Mapeamento de Cenas';

  @override
  String get sceneModelMappingDesc =>
      'Prestadores de ligações e modelos por cena. Cenas não ligadas continuarão usando o modelo padrão.';

  @override
  String get sceneModelRefreshList => 'Atualizar lista de modelos';

  @override
  String get sceneModelSearchHint =>
      'Clique no botão à direita para procurar, colapsar e selecionar modelos pelo Provedor; A barra de busca fica fixa.';

  @override
  String get sceneModelNoScenes => 'Sem cenas configuráveis.';

  @override
  String get sceneModelLoadFailed =>
      'Não foi possível carregar as configurações do modelo de cena.';

  @override
  String sceneModelPartialUpdateFailed(Object profiles) {
    return 'Atualizei alguns modelos, mas esses fornecedores falharam. $profiles';
  }

  @override
  String sceneModelUpdatedModels(Object count) {
    return '$count modelos atualizados';
  }

  @override
  String sceneModelRefreshFailed(Object error) {
    return 'Falha em atualizar a lista de modelos: $error';
  }

  @override
  String get sceneModelInvalidModelId =>
      'A identificação do modelo não pode começar com cena.';

  @override
  String sceneModelBoundToast(Object scene, Object model) {
    return '$scene agora está usando $model';
  }

  @override
  String sceneModelSaveFailed(Object scene, Object error) {
    return 'Falhou em salvar $scene: $error';
  }

  @override
  String sceneModelBindingCleared(Object scene) {
    return 'Limpou a ligação para $scene';
  }

  @override
  String sceneModelDefaultRestored(Object scene) {
    return '$scene está de volta ao modelo padrão.';
  }

  @override
  String sceneModelClearFailed(Object scene, Object error) {
    return 'Não consegui limpar. $scene: $error';
  }

  @override
  String get modelsNoAvailableModels => 'Nenhum modelo disponível.';

  @override
  String get alarmSaved => 'Configurações de alarme salvas';

  @override
  String get alarmRingtoneSource => 'Fonte do toque';

  @override
  String get alarmSystemDefault => 'Padrão do Sistema';

  @override
  String get alarmSystemDefaultDesc =>
      'Nenhuma configuração extra necessária, melhor compatibilidade.';

  @override
  String get alarmLocalMp3 => 'MP3 local';

  @override
  String get alarmLocalMp3Desc =>
      'Selecione um arquivo MP3 em seu telefone como o toque do alarme';

  @override
  String get alarmMp3Url => 'URL MP3';

  @override
  String get alarmMp3UrlDesc => 'Use um URL HTTP(S) para tocar um MP3 online';

  @override
  String get alarmAudioPermissionDenied =>
      'Permissão de leitura de áudio não concedida';

  @override
  String get alarmInvalidFilePath =>
      'Caminho de arquivo inválido, selecione novamente';

  @override
  String get alarmSelectLocalFirst =>
      'Por favor, selecione um arquivo MP3 local primeiro.';

  @override
  String get alarmEnterHttpsUrl => 'Por favor, insira um URL HTTP(S) MP3';

  @override
  String get alarmLocalFile => 'Arquivo Local';

  @override
  String get alarmSelectMp3 => 'Selecione arquivo MP3';

  @override
  String get authorizePageTitle => 'Autorização do aplicativo';

  @override
  String get authorizeReceiveNotifications =>
      'Receba notificações de mensagens.';

  @override
  String get authorizeNotificationsDesc =>
      'Ative isso para obter atualizações do progresso da tarefa a tempo.';

  @override
  String get storageUsageTitle => 'Uso de Armazenamento';

  @override
  String get storageUsageSubtitle =>
      'Veja os detalhes do uso do armazenamento e limpe por categoria.';

  @override
  String get storageAnalyzeFailed =>
      'Análise de armazenamento falhou, por favor tente novamente';

  @override
  String storageCategoryCleaned(Object name, Object size) {
    return 'Limpa $name, livre $size';
  }

  @override
  String get storageCleanFailed =>
      'A limpeza falhou, por favor tente de novo mais tarde.';

  @override
  String storageCleanCategory(Object name) {
    return 'Limpo. $name';
  }

  @override
  String get storageCleanConfirmMsg => 'Confirmar a limpeza desta categoria?';

  @override
  String get storageCleanScope => 'Escopo de limpeza';

  @override
  String get storageCleanAll => 'Todos';

  @override
  String get storageClean7Days => '7 dias atrás';

  @override
  String get storageClean30Days => '30 dias atrás';

  @override
  String storageStrategyName(Object name) {
    return 'Estratégia: $name';
  }

  @override
  String storageStrategyDone(Object size) {
    return 'Estratégia completada, libertada $size';
  }

  @override
  String storageStrategyPartialDone(Object count, Object size) {
    return 'Estratégia concluída: $size liberados; $count itens não foram concluídos.';
  }

  @override
  String get storageStrategyFailed =>
      'Estratégia falhou, por favor tente novamente mais tarde.';

  @override
  String get storageLoadFailed => 'Falha ao carregar.';

  @override
  String get storageReanalyze => 'Reanalisar';

  @override
  String get storageTotalUsage => 'Uso Total';

  @override
  String get storageAppSize => 'Tamanho do aplicativo';

  @override
  String get storageUserData => 'Dados do Usuário';

  @override
  String get storageCleanable => 'Limpo.';

  @override
  String storageStatsSource(Object source) {
    return 'Fonte estatística: $source';
  }

  @override
  String storagePackageName(Object name) {
    return 'Pacote atual: $name';
  }

  @override
  String get storageTrendFirst =>
      'Esta é a primeira análise. Tendências de uso serão mostradas em análises futuras.';

  @override
  String get storageSmartCleanup => 'Limpeza inteligente.';

  @override
  String get storageExecute => 'Executar';

  @override
  String get storageUsageAnalysis => 'Análise de Uso';

  @override
  String get storageClean => 'Limpo.';

  @override
  String get storageRiskLow => 'Baixo Risco';

  @override
  String get storageRiskCaution => 'Cuidado.';

  @override
  String get storageRiskHigh => 'Alto Risco';

  @override
  String get storageReadOnly => 'Apenas leitura';

  @override
  String get storageSystemStats =>
      'Estatísticas do sistema (mais perto das configurações do sistema)';

  @override
  String get storageDirectoryScan => 'Estimativa de varredura de diretórios';

  @override
  String get storageAdditionalInfo => 'Informações adicionais';

  @override
  String get storageCatAppBinary => 'App Binary';

  @override
  String get storageCatAppBinaryDesc =>
      'Arquivos de aplicativos instalados (APK/AAB split)';

  @override
  String get storageCatCache => 'Cache.';

  @override
  String get storageCatCacheDesc =>
      'Arquivos temporários e cache de imagens, seguros para limpar.';

  @override
  String get storageCatCacheHint =>
      'Vai regenerar automaticamente durante o uso após a limpeza';

  @override
  String get storageCatConversation => 'História da Conversa';

  @override
  String get storageCatConversationDesc =>
      'História de execução de bate-papo e ferramenta (estimada)';

  @override
  String get storageCatConversationHint =>
      'Apagará registros históricos de mensagens e não poderá ser recuperado.';

  @override
  String get storageCatDatabaseOther => 'Outro banco de dados';

  @override
  String get storageCatDatabaseOtherDesc => 'Índices e tabelas do sistema';

  @override
  String get storageCatWorkspaceBrowser =>
      'Artefatos de navegador de espaço de trabalho';

  @override
  String get storageCatWorkspaceBrowserDesc =>
      'Imagens de navegador, downloads e arquivos intermediários';

  @override
  String get storageCatWorkspaceBrowserHint =>
      'Apagará arquivos intermediários da ferramenta do navegador';

  @override
  String get storageCatWorkspaceOffloads => 'Espaço de trabalho Offloads';

  @override
  String get storageCatWorkspaceOffloadsDesc =>
      'Ferramentas offline e arquivos temporários';

  @override
  String get storageCatWorkspaceOffloadsHint =>
      'Só apaga artefatos offline, não afeta a funcionalidade central.';

  @override
  String get storageCatWorkspaceAttachments => 'Anexos do espaço de trabalho';

  @override
  String get storageCatWorkspaceAttachmentsDesc =>
      'Arquivos de anexos usados por tarefas históricas';

  @override
  String get storageCatWorkspaceAttachmentsHint =>
      'Pode afetar a visualização de anexos em tarefas históricas.';

  @override
  String get storageCatWorkspaceShared => 'Espaço de trabalho compartilhado';

  @override
  String get storageCatWorkspaceSharedDesc =>
      'Arquivos compartilhados de espaço de trabalho em tarefas';

  @override
  String get storageCatWorkspaceSharedHint =>
      'Pode afetar tarefas subsequentes reutilizando arquivos compartilhados.';

  @override
  String get storageCatWorkspaceMemory =>
      'Dados de memória do espaço de trabalho';

  @override
  String get storageCatWorkspaceMemoryDesc =>
      'Memória de longo/curto prazo e dados de índice';

  @override
  String get storageCatWorkspaceUserFiles =>
      'Arquivos do usuário do espaço de trabalho';

  @override
  String get storageCatWorkspaceUserFilesDesc =>
      'Arquivos salvos manualmente no espaço de trabalho pelo usuário';

  @override
  String get storageCatTerminalLocal => 'Terminal Runtime (local)';

  @override
  String get storageCatTerminalLocalDesc =>
      'Alpine/Ubuntu terminal diretório local runtime';

  @override
  String get storageCatTerminalLocalHint =>
      'Apagará o diretório local terminal, precisa ser reinicializado.';

  @override
  String get storageCatTerminalBootstrap => 'Terminal Runtime (bootstrap)';

  @override
  String get storageCatTerminalBootstrapDesc =>
      'Proot/lib/rootfs inicia arquivos';

  @override
  String get storageCatTerminalBootstrapHint =>
      'Apagará os arquivos do terminal, precisa ser reinicializado.';

  @override
  String get storageCatSharedDrafts => 'Rascunhos compartilhados';

  @override
  String get storageCatSharedDraftsDesc =>
      'Rascunho do cache das importações de compartilhamento externo.';

  @override
  String get storageCatSharedDraftsHint => 'Apagará anexos não enviados.';

  @override
  String get storageCatMcpInbox => 'MCP Inbox';

  @override
  String get storageCatMcpInboxDesc =>
      'Transferência de arquivos MCP recebe diretório';

  @override
  String get storageCatMcpInboxHint =>
      'Vai apagar arquivos na caixa de entrada MCP';

  @override
  String get storageCatLegacyWorkspace => 'Dados Legados';

  @override
  String get storageCatLegacyWorkspaceDesc =>
      'Diretórios antigos possivelmente deixados após a atualização';

  @override
  String get storageCatLegacyWorkspaceHint =>
      'Confirme que não é mais necessário antes da limpeza.';

  @override
  String get storageCatOtherUserData => 'Outros Dados';

  @override
  String get storageCatOtherUserDataDesc =>
      'Dados não correspondem a nenhuma regra de categoria.';

  @override
  String get storageStrategySafeQuick => 'Limpeza rápida segura';

  @override
  String get storageStrategySafeQuickDesc =>
      'Priorizar limpeza de baixo risco e artefatos temporários';

  @override
  String get storageStrategyBalanceDeep => 'Limpeza Profunda Equilibrada';

  @override
  String get storageStrategyBalanceDeepDesc =>
      'Livre mais espaço enquanto mantém os dados e arquivos do usuário.';

  @override
  String get storageStrategyFree1gb => 'Alvo livre 1GB';

  @override
  String get storageStrategyFree1gbDesc =>
      'Limpo em ordem de alto valor, visando 1GB de alvo de liberação';

  @override
  String get storageHintConversation =>
      'Se a história não for divulgada, entre novamente na página e execute "Reanalisar"';

  @override
  String get storageHintTerminal =>
      'Após o tempo de execução do terminal ser limpo, você pode reiniciá-lo da página do Ambiente Terminal.';

  @override
  String get storageHintGeneral =>
      'Se a limpeza falhar, tente novamente mais tarde ou reinicie o aplicativo.';

  @override
  String get storageHintNotCleanable =>
      'Esta categoria não é limpo atualmente.';

  @override
  String get storageHintSkipped => 'Esta categoria foi ignorada (opcional)';

  @override
  String storageCleanPartialFailed(Object hint) {
    return 'Alguma limpeza falhou. $hint';
  }

  @override
  String get storageCleanPartialFailedGeneric =>
      'Alguns arquivos falharam em limpar, por favor tente novamente mais tarde.';

  @override
  String storageTrendVsLast(Object cleanable, Object total) {
    return 'Vs última análise: total $total, limpo $cleanable';
  }

  @override
  String storageLastAnalyzed(Object time) {
    return 'Última análise: $time';
  }

  @override
  String get aboutDescription =>
      'A Melly é uma assistente de IA focada em conversas inteligentes. Ela usa compreensão semântica e aprendizado contínuo para ajudar no processamento de informações, no apoio a decisões e na organização do dia a dia.';

  @override
  String get aboutBetaProgramTitle => 'Junte-se aos testes beta.';

  @override
  String get aboutBetaProgramDescription =>
      'Receba atualizações beta mais rápidas de quatro partes.';

  @override
  String get aboutBetaProgramToggleFailed =>
      'Não foi possível atualizar a preferência dos testes beta.';

  @override
  String get aboutPreferencesSectionTitle => 'Atualizar e testar';

  @override
  String get aboutApkSourceTitle => 'Fonte de Download APK';

  @override
  String get aboutApkSourceDescription =>
      'Escolha a fonte usada para instalação de atualização.';

  @override
  String get aboutApkSourceDisclaimer =>
      'Ao usar este aplicativo, você concorda com nossa Política de Privacidade e concorda com a coleta de informações de uso anônimo através do trabalhador de atualização de código aberto. para ajudar a melhorar o software. Você é o único responsável por qualquer perda ou consequência decorrente de seu uso do aplicativo.';

  @override
  String get aboutApkSourceOptionCnb => 'Cloudflare R2';

  @override
  String get aboutApkSourceOptionCnbDescription =>
      'Servido pelo trabalhador de atualização.';

  @override
  String get aboutApkSourceOptionGithub => 'GitHub.';

  @override
  String get aboutApkSourceOptionGithubDescription =>
      'Fonte oficial de liberação';

  @override
  String get aboutApkSourceSwitchFailed =>
      'Não foi possível mudar a fonte de download do APK.';

  @override
  String get aboutUpdateHintDefault =>
      'Procure por atualizações para obter a última versão.';

  @override
  String get workspaceMemoryLoadFailed =>
      'Falha ao carregar a configuração da memória do espaço de trabalho';

  @override
  String get agentSoulSaved => '"Arma agente salva".';

  @override
  String get agentSoulSaveFailed => 'Falhou em salvar a alma do agente.';

  @override
  String get chatPromptSaved => 'O sistema só de bate-papo foi salvo.';

  @override
  String get chatPromptSaveFailed =>
      'Não foi possível salvar o prompt do sistema somente para chat.';

  @override
  String get workspaceMemorySaved => 'MEMÓRIA. MD salvou';

  @override
  String get workspaceMemorySaveFailed => 'Falhou em salvar a memória.';

  @override
  String get workspaceEmbeddingToggleFailed =>
      'Não foi possível atualizar a memória incorporando a opção';

  @override
  String get workspaceRollupToggleFailed =>
      'Não foi possível atualizar a mudança noturna.';

  @override
  String get workspaceRollupDone => 'Rollup completo.';

  @override
  String get workspaceRollupFailed => 'O rolo falhou.';

  @override
  String get workspaceNone => 'Nenhum.';

  @override
  String get workspaceMemoryTitle => 'Memória do espaço de trabalho';

  @override
  String get workspaceMemoryCapability => 'Capacidade da memória';

  @override
  String get workspaceEmbeddingReady =>
      'Configurado, recuperação vetorial disponível.';

  @override
  String get workspaceEmbeddingNotReady =>
      'Não configurado, vai voltar para recuperação lexical';

  @override
  String get workspaceGoToConfig =>
      'Vá para a configuração do modelo de cena para configurar o modelo de incorporação';

  @override
  String get workspaceNightlyRollup => 'Rollup da Memória Noturna (22:00)';

  @override
  String workspaceLastRun(Object time) {
    return 'Última execução: $time';
  }

  @override
  String workspaceNextRun(Object time) {
    return 'Próxima execução: $time';
  }

  @override
  String get workspaceRollupNow => 'Role agora.';

  @override
  String get workspaceSettingsAndMemory => 'Configurações do Agente e Memória';

  @override
  String get agentSoulSetting => 'Agente Soul.';

  @override
  String get chatPromptSetting => 'Chamada de sistema só para bate-papo.';

  @override
  String get workspaceMemoryMd => 'MEMÓRIA.';

  @override
  String get alpineNodeJs => 'Node.js Runtime';

  @override
  String get alpineNpm => 'Gerente de Pacotes Node.Js';

  @override
  String get alpineGit => 'Controle de Versão Git';

  @override
  String get alpinePython => 'Interpretador Python';

  @override
  String get alpinePip => 'Projetos e Pacotes Python';

  @override
  String get alpinePipInstall => 'Instalador de Pacotes Python';

  @override
  String get alpineCodex => 'CLI OpenAI Codex para agentes ACP';

  @override
  String get alpineClaudeCode => 'Código Antrópico Claude CLI para agentes ACP';

  @override
  String get alpineOpenCode => 'OpenCode CLI com suporte ACP embutido';

  @override
  String get alpineDeepSeekHarness =>
      'DeepSeek Harness (dsh) oficial ACP corrida';

  @override
  String get alpineKimiCode => 'Kimi Code oficial CLI e Web UI local';

  @override
  String get alpineSshClient => 'Cliente SSH';

  @override
  String get alpineSshpass => 'SSH Password Helper';

  @override
  String get alpineOpenSshServer => 'OpenSSH Server';

  @override
  String get alpineDetectFailed =>
      'Não foi possível detectar o ambiente terminal.';

  @override
  String get alpineBootTasksLoadFailed =>
      'Não foi possível carregar as tarefas de inicialização.';

  @override
  String get alpineConfigOpenFailed =>
      'Falha ao abrir a configuração do ambiente terminal';

  @override
  String get alpineBootTaskAdded => 'Tarefa de inicialização adicionada';

  @override
  String get alpineBootTaskUpdated => 'Tarefa de inicialização atualizada';

  @override
  String get alpineBootTaskSaveFailed =>
      'Falha ao salvar a tarefa de inicialização';

  @override
  String get alpineBootEnabled =>
      'Auto-inicialização ativada no lançamento do aplicativo';

  @override
  String get alpineBootDisabled => 'Auto-início desativado';

  @override
  String get alpineBootTaskUpdateFailed =>
      'Não foi possível atualizar a tarefa';

  @override
  String get alpineDeleteBootTask => 'Excluir Tarefa de Bota';

  @override
  String alpineDeleteBootTaskMsg(Object name) {
    return 'Excluir "$name"?';
  }

  @override
  String get alpineBootTaskDeleted => 'Tarefa de inicialização apagada';

  @override
  String get alpineBootTaskDeleteFailed => 'Não foi possível excluir a tarefa';

  @override
  String get alpineCommandSent => 'Iniciar comando enviado';

  @override
  String get alpineStartFailed => 'Não foi possível iniciar a tarefa.';

  @override
  String get alpineDetecting => 'Detectando o ambiente';

  @override
  String alpineStartConfig(Object count) {
    return 'Iniciar configuração ($count itens)';
  }

  @override
  String get alpineAllReady => 'Tudo pronto.';

  @override
  String get alpineDetectingDesc =>
      'Detectando informações de versão de ferramentas comuns de desenvolvimento no sistema terminal selecionado.';

  @override
  String alpineReadyCount(Object ready, Object total) {
    return '$ready/$total itens prontos no sistema de terminal selecionado. Verifique os itens ausentes e configure-os automaticamente no ReTerminal.';
  }

  @override
  String get alpineBootTasks => 'Tarefas de inicialização';

  @override
  String get alpineBootTasksDesc =>
      'Quando Melly abre, tarefas habilitadas são verificadas em segundo plano e comandos são iniciados na sessão Reterminal correspondente. Adequado para serviços persistentes.';

  @override
  String get alpineAddTask => 'Adicionar tarefa';

  @override
  String get alpineOpenTerminal => 'Abrir Terminal';

  @override
  String get alpineNoTasksDesc =>
      'Sem tarefas. Você pode adicionar comandos persistentes como "python app.py", "node server.js", ou "./start.sh".';

  @override
  String get alpineBootOnAppOpen =>
      'Comece depois que o aplicativo abrir no arranque.';

  @override
  String get alpineNotEnabled => 'Não habilitado.';

  @override
  String get alpineRunning => 'Correndo.';

  @override
  String get alpineStartNow => 'Comece agora.';

  @override
  String get alpineEdit => 'Editar';

  @override
  String get alpineVersionDetected => 'Versão detectada.';

  @override
  String get alpineVersionNotFound => 'Não detectado.';

  @override
  String get alpineTaskNameHint => 'Digite o nome da tarefa';

  @override
  String get alpineCommandHint => 'Digite o comando de início';

  @override
  String get alpineEditBootTask => 'Editar tarefa de inicialização';

  @override
  String get alpineAddBootTask => 'Adicionar tarefa de inicialização';

  @override
  String get alpineTaskName => 'Nome da tarefa';

  @override
  String get alpineTaskNameExample => 'Por exemplo, serviço de API local';

  @override
  String get alpineStartCommand => 'Iniciar comando';

  @override
  String get alpineCommandExample => 'Por exemplo, app de python.';

  @override
  String get alpineWorkDir => 'Diretório de trabalho';

  @override
  String get alpineBootAutoStart =>
      'Iniciar automaticamente quando a Melly abrir';

  @override
  String get alpineDevEnv => 'Ambiente Dev';

  @override
  String get alpineAiAgent => 'Agente Al.';

  @override
  String get alpineEnvConfig => 'Configuração do Ambiente';

  @override
  String alpineWorkDirValue(Object dir) {
    return 'Diretório de trabalho: $dir';
  }

  @override
  String get workspaceEmbeddingRetrieval => 'Memória Embutindo Recuperação';

  @override
  String get chatHistoryStartConversation => 'Comece uma conversa.';

  @override
  String get homeDrawerSearching => 'Procurando conversas...';

  @override
  String get homeDrawerNoResults => 'Nenhuma conversa foi encontrada.';

  @override
  String get homeDrawerSearchHint2 =>
      'Tente palavras-chave mais curtas ou reformule sua pesquisa.';

  @override
  String get homeDrawerSearchResults => 'Resultados da pesquisa';

  @override
  String get homeDrawerResultCount => 'resultados';

  @override
  String get homeDrawerScheduled => 'Agendado.';

  @override
  String get homeDrawerScheduledTasks => 'Tarefas agendadas';

  @override
  String get homeDrawerPinnedConversations => 'Conversa fiada.';

  @override
  String get homeDrawerAgentSection => 'Agente.';

  @override
  String get homeDrawerOmniAiSection => 'Melly';

  @override
  String get homeDrawerChatOnlySection => 'Conversa pura.';

  @override
  String get homeDrawerAgentNoProject => 'Outro';

  @override
  String get homeDrawerGreeting => 'Olá!';

  @override
  String get homeDrawerWelcome => 'Boas-vindas à Melly';

  @override
  String get homeDrawerDawnGreeting => 'Tarde da noite';

  @override
  String get homeDrawerDawnSub => 'Ainda acordada?';

  @override
  String get homeDrawerDawnGreeting2 => 'Antes do amanhecer';

  @override
  String get homeDrawerDawnSub2 => 'Pássaro madrugador, cuide-se!';

  @override
  String get homeDrawerDawnGreeting3 => 'Meia-noite quieta.';

  @override
  String get homeDrawerDawnSub3 => 'Lembre-se de descansar.';

  @override
  String get homeDrawerMorningGreeting => 'Bom dia!';

  @override
  String get homeDrawerMorningSub => 'Comece seu dia com energia';

  @override
  String get homeDrawerMorningGreeting2 => 'Bom dia!';

  @override
  String get homeDrawerMorningSub2 => 'Um novo dia começou';

  @override
  String get homeDrawerForenoonGreeting => 'Bom dia!';

  @override
  String get homeDrawerForenoonSub => 'Dê uma esticada rápida no ombro';

  @override
  String get homeDrawerForenoonGreeting2 => 'Grande momento!';

  @override
  String get homeDrawerForenoonSub2 => 'Continue assim.';

  @override
  String get homeDrawerLunchGreeting => 'Hora do almoço!';

  @override
  String get homeDrawerLunchSub => 'Tenha uma refeição adequada.';

  @override
  String get homeDrawerLunchGreeting2 => 'Boa tarde.';

  @override
  String get homeDrawerLunchSub2 => 'Faça uma pausa depois do almoço.';

  @override
  String get homeDrawerLunchGreeting3 => 'Não sabe o que comer?';

  @override
  String get homeDrawerLunchSub3 => 'Deixe a Melly recomendar algo para você';

  @override
  String get homeDrawerAfternoonGreeting => 'Hora de uma pausa para o chá';

  @override
  String get homeDrawerAfternoonSub => 'Você consegue!';

  @override
  String get homeDrawerAfternoonGreeting2 => 'Olhe para o outro lado.';

  @override
  String get homeDrawerAfternoonSub2 => 'Refresque seus olhos por um momento';

  @override
  String get homeDrawerEveningGreeting => 'Tenha calma no caminho de casa.';

  @override
  String get homeDrawerEveningSub => 'Relaxe esta noite.';

  @override
  String get homeDrawerEveningGreeting2 => 'Brisa da noite';

  @override
  String get homeDrawerEveningSub2 => 'É bom, não é?';

  @override
  String get homeDrawerEveningGreeting3 => 'Dia longo hoje.';

  @override
  String get homeDrawerEveningSub3 => 'Prepare-se para uma boa refeição.';

  @override
  String get homeDrawerNightGreeting => 'Boa noite!';

  @override
  String get homeDrawerNightSub => 'Aproveite seu próprio tempo.';

  @override
  String get homeDrawerNightGreeting2 => 'A noite está se instalando';

  @override
  String get homeDrawerNightSub2 => 'Prepare-se para descansar mais cedo.';

  @override
  String get homeDrawerNightGreeting3 => 'Hora de descansar.';

  @override
  String get homeDrawerNightSub3 => 'Deixe a Melly definir um alarme para você';

  @override
  String get homeDrawerLateNightGreeting =>
      'Abaixe o telefone e durma mais cedo.';

  @override
  String get homeDrawerLateNightSub => 'Recarregue para amanhã';

  @override
  String get homeDrawerLateNightGreeting2 => 'Está tarde.';

  @override
  String get homeDrawerLateNightSub2 => 'Diga boa noite para hoje.';

  @override
  String get languagePortugueseBrazil => 'Português (Brasil)';
}
