package cn.com.omnimind.baselib.i18n

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Locale

class AppLocaleManagerTest {
    @Test
    fun resolvePromptLocaleRespectsExplicitModeAndSystemFallback() {
        assertEquals(
            PromptLocale.EN_US,
            AppLocaleManager.resolvePromptLocale(AppLanguageMode.EN, Locale.SIMPLIFIED_CHINESE)
        )
        assertEquals(
            PromptLocale.ZH_CN,
            AppLocaleManager.resolvePromptLocale(AppLanguageMode.ZH_HANS, Locale.US)
        )
        assertEquals(
            PromptLocale.EN_US,
            AppLocaleManager.resolvePromptLocale(AppLanguageMode.SYSTEM, Locale.US)
        )
        assertEquals(
            PromptLocale.ZH_CN,
            AppLocaleManager.resolvePromptLocale(AppLanguageMode.SYSTEM, Locale.SIMPLIFIED_CHINESE)
        )
        assertEquals(
            PromptLocale.PT_BR,
            AppLocaleManager.resolvePromptLocale(AppLanguageMode.PT_BR, Locale.US)
        )
        assertEquals(
            PromptLocale.PT_BR,
            AppLocaleManager.resolvePromptLocale(AppLanguageMode.SYSTEM, Locale.forLanguageTag("pt-BR"))
        )
    }

    @Test
    fun localizedTextFallsBackToEnglishWhenPortugueseIsMissing() {
        val text = LocalizedText(zhCN = "中文", enUS = "English")

        assertEquals("English", text.resolve(PromptLocale.PT_BR))
        assertEquals(
            "Português",
            text.copy(ptBR = "Português").resolve(PromptLocale.PT_BR)
        )
    }
}
