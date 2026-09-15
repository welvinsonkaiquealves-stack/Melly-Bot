package cn.com.omnimind.bot.agent.tool.handlers

import android.content.Context
import cn.com.omnimind.baselib.llm.AssistantToolCall
import cn.com.omnimind.baselib.llm.AssistantToolCallFunction
import cn.com.omnimind.baselib.shizuku.PrivilegedActionPolicy
import cn.com.omnimind.baselib.shizuku.PrivilegedResult
import cn.com.omnimind.baselib.shizuku.ShizukuBackend
import cn.com.omnimind.baselib.shizuku.ShizukuCapabilityManager
import cn.com.omnimind.baselib.shizuku.ShizukuStatus
import cn.com.omnimind.baselib.shizuku.ShizukuStatusCode
import cn.com.omnimind.bot.agent.AgentCallback
import cn.com.omnimind.bot.agent.AgentExecutionEnvironment
import cn.com.omnimind.bot.agent.AgentToolRegistry
import cn.com.omnimind.bot.agent.AgentWorkspaceDescriptor
import cn.com.omnimind.bot.agent.AgentWorkspaceManager
import cn.com.omnimind.bot.agent.NoOpAgentRunControl
import cn.com.omnimind.bot.agent.ToolExecutionResult
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.mockito.ArgumentMatchers.nullable
import org.mockito.Mockito.doAnswer
import org.mockito.Mockito.doReturn
import org.mockito.Mockito.mock
import org.mockito.Mockito.mockingDetails
import org.mockito.Mockito.`when`

class PrivilegedToolHandlerApprovalTest {
    @Test
    fun `model confirmed flag cannot bypass rejected user approval`() = runBlocking {
        var approvalRequests = 0
        val fixture = fixture(
            requester = cn.com.omnimind.bot.agent.AgentPermissionRequester { _, _, _ ->
                approvalRequests++
                false
            },
        )

        val result = fixture.execute(command = "id", modelConfirmed = true)

        assertTrue(result is ToolExecutionResult.Error)
        assertEquals(1, approvalRequests)
        fixture.assertNoPrivilegedBackendCall()
    }

    @Test
    fun `system approval releases backend with an internally produced confirmation`() = runBlocking {
        var approvalRequests = 0
        val fixture = fixture(
            requester = cn.com.omnimind.bot.agent.AgentPermissionRequester { _, _, _ ->
                approvalRequests++
                true
            },
        )
        fixture.stubSuccessfulRawShell("id")

        val result = fixture.execute(command = "id", modelConfirmed = false)

        assertTrue(result is ToolExecutionResult.ContextResult)
        assertEquals(1, approvalRequests)
        fixture.assertRawShellCalledWithInternalConfirmation()
    }

    @Test
    fun `missing approval channel fails closed even when model sends confirmed`() = runBlocking {
        val fixture = fixture(requester = null)

        val result = fixture.execute(command = "id", modelConfirmed = true)

        assertTrue(result is ToolExecutionResult.Error)
        fixture.assertNoPrivilegedBackendCall()
    }

    @Test
    fun `model confirmed flag cannot bypass session start approval`() = runBlocking {
        var approvalRequests = 0
        val fixture = fixture(
            requester = cn.com.omnimind.bot.agent.AgentPermissionRequester { _, _, _ ->
                approvalRequests++
                false
            },
        )

        val result = fixture.executeTool(
            toolName = "android_privileged_session_start",
            args = Json.parseToJsonElement("""{"confirmed":true}""").jsonObject,
        )

        assertTrue(result is ToolExecutionResult.Error)
        assertEquals(1, approvalRequests)
        fixture.assertNoPrivilegedBackendCall()
    }

    @Test
    fun `model confirmed flag cannot bypass session command approval`() = runBlocking {
        var approvalRequests = 0
        val fixture = fixture(
            requester = cn.com.omnimind.bot.agent.AgentPermissionRequester { _, _, _ ->
                approvalRequests++
                false
            },
        )

        val result = fixture.executeTool(
            toolName = "android_privileged_session_exec",
            args = Json.parseToJsonElement(
                """{"sessionId":"session-1","command":"id","confirmed":true}""",
            ).jsonObject,
        )

        assertTrue(result is ToolExecutionResult.Error)
        assertEquals(1, approvalRequests)
        fixture.assertNoPrivilegedBackendCall()
    }

    @Test
    fun `blocked command is rejected before approval regardless of model confirmed flag`() = runBlocking {
        var approvalRequests = 0
        val fixture = fixture(
            requester = cn.com.omnimind.bot.agent.AgentPermissionRequester { _, _, _ ->
                approvalRequests++
                true
            },
        )

        val result = fixture.execute(command = "reboot", modelConfirmed = true)

        assertTrue(result is ToolExecutionResult.Error)
        assertEquals(0, approvalRequests)
        fixture.assertNoPrivilegedBackendCall()
    }

    private fun fixture(
        requester: cn.com.omnimind.bot.agent.AgentPermissionRequester?,
    ): Fixture {
        val context = mock(Context::class.java)
        val helper = mock(SharedHelper::class.java)
        doReturn(context).`when`(helper).context
        doReturn(true).`when`(helper).isEnglishLocale
        doAnswer { call -> call.getArgument<String?>(0).orEmpty() }
            .`when`(helper).localized(nullable(String::class.java))
        doReturn(emptyMap<String, String>()).`when`(helper).parseEnvironmentMap(null)
        doReturn("{}").`when`(helper).encodeLocalizedPayload(nullable(Any::class.java))

        val manager = mock(ShizukuCapabilityManager::class.java)
        `when`(manager.getStatus()).thenReturn(
            ShizukuStatus(
                code = ShizukuStatusCode.GRANTED_ADB,
                backend = ShizukuBackend.ADB,
                installed = true,
                running = true,
                permissionGranted = true,
                binderReady = true,
                serviceBound = true,
                availableActions = listOf(PrivilegedActionPolicy.ACTION_SHELL_EXEC),
            ),
        )
        val environment = mock(AgentExecutionEnvironment::class.java)
        `when`(environment.permissionRequester).thenReturn(requester)
        val workspace = mock(AgentWorkspaceDescriptor::class.java)
        `when`(workspace.id).thenReturn("workspace")
        `when`(environment.workspaceDescriptor).thenReturn(workspace)
        val terminalToolHandler = mock(TerminalToolHandler::class.java)
        `when`(
            terminalToolHandler.isOwnedTerminalSession(
                "${SharedHelper.PRIVILEGED_SESSION_WORKSPACE_PREFIX}workspace",
                "session-1",
            ),
        ).thenReturn(true)
        val handler = PrivilegedToolHandler(
            helper = helper,
            workspaceManager = mock(AgentWorkspaceManager::class.java),
            terminalToolHandler = terminalToolHandler,
            shizukuManagerProvider = { manager },
        )
        return Fixture(handler, helper, manager, environment)
    }

    private class Fixture(
        private val handler: PrivilegedToolHandler,
        private val helper: SharedHelper,
        private val manager: ShizukuCapabilityManager,
        private val environment: AgentExecutionEnvironment,
    ) {
        suspend fun execute(command: String, modelConfirmed: Boolean): ToolExecutionResult {
            val rawArguments = Json.parseToJsonElement(
                """{"command":"$command","confirmed":$modelConfirmed}""",
            ).jsonObject
            doReturn(mapOf("command" to command))
                .`when`(helper)
                .jsonObjectToStringMap(
                    rawArguments,
                    excludedKeys = setOf("environment", "confirmed"),
                )
            val args = JsonObject(
                mapOf(
                    "action" to kotlinx.serialization.json.JsonPrimitive(PrivilegedActionPolicy.ACTION_SHELL_EXEC),
                    "arguments" to rawArguments,
                ),
            )
            return executeTool("android_privileged_action", args)
        }

        suspend fun executeTool(toolName: String, args: JsonObject): ToolExecutionResult {
            val toolCallId = "privileged-test"
            return handler.execute(
                toolCall = AssistantToolCall(
                    id = toolCallId,
                    function = AssistantToolCallFunction(
                        name = toolName,
                        arguments = args.toString(),
                    ),
                ),
                args = args,
                runtimeDescriptor = AgentToolRegistry.RuntimeToolDescriptor(
                    name = toolName,
                    displayName = "Privileged action",
                    toolType = "privileged",
                ),
                env = environment,
                callback = mock(AgentCallback::class.java),
                toolHandle = NoOpAgentRunControl.beginToolExecution(
                    toolName = toolName,
                    toolCallId = toolCallId,
                ),
            )
        }

        fun assertNoPrivilegedBackendCall() {
            val privilegedCalls = mockingDetails(manager).invocations.filter {
                it.method.name in setOf(
                    "executeRawShell",
                    "executeAgentAction",
                    "startPrivilegedSession",
                    "execPrivilegedSession",
                )
            }
            assertTrue("Privileged backend must not run without system approval", privilegedCalls.isEmpty())
        }

        suspend fun stubSuccessfulRawShell(command: String) {
            `when`(
                manager.executeRawShell(
                    command = command,
                    timeoutSeconds = null,
                    workingDirectory = null,
                    environment = emptyMap(),
                    confirmed = true,
                ),
            ).thenReturn(
                PrivilegedResult(
                    requestId = "backend-result",
                    action = PrivilegedActionPolicy.ACTION_SHELL_EXEC,
                    success = true,
                    code = "ok",
                    message = "ok",
                    backend = ShizukuBackend.ADB,
                    command = command,
                ),
            )
        }

        fun assertRawShellCalledWithInternalConfirmation() {
            val calls = mockingDetails(manager).invocations.filter {
                it.method.name == "executeRawShell"
            }
            assertEquals(1, calls.size)
            assertTrue(calls.single().arguments.any { it == true })
        }
    }
}
