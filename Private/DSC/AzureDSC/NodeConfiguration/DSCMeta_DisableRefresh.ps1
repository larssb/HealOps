[DscLocalConfigurationManager()]
Configuration DSCMeta_DisableRefresh {
    Node "localhost" {
       Settings {
           RefreshMode = "Disabled"
       }
    }
}

DSCMeta_DisableRefresh