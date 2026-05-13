package com.simpleshift.scheduler

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.simpleshift.scheduler.calendar.CalendarEventManager
import com.simpleshift.scheduler.calendar.CalendarSyncManager
import com.simpleshift.scheduler.data.repository.SettingsRepository
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.ui.calendar.CalendarScreen
import com.simpleshift.scheduler.ui.home.HomeScreen
import com.simpleshift.scheduler.ui.settings.SettingsScreen
import com.simpleshift.scheduler.viewmodel.CalendarViewModel
import com.simpleshift.scheduler.viewmodel.HomeViewModel
import com.simpleshift.scheduler.viewmodel.SettingsViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val homeViewModel: HomeViewModel by viewModels()
    private val calendarViewModel: CalendarViewModel by viewModels()
    private lateinit var settingsRepository: SettingsRepository
    private lateinit var calendarSyncManager: CalendarSyncManager
    private val runtimeSettingsFlow = MutableStateFlow(RuntimeShiftSettings())

    private val requestCalendarPermissionsLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (permissions.any { it.value == true }) {
            calendarSyncManager.syncFromCurrentState()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        settingsRepository = SettingsRepository(applicationContext)
        val calendarEventManager = CalendarEventManager(this)
        calendarSyncManager = CalendarSyncManager(
            this, settingsRepository, calendarEventManager,
            runtimeSettingsFlow, lifecycleScope
        )

        lifecycleScope.launch {
            settingsRepository.settingsFlow.collect { settings ->
                if (settings.isValid) {
                    runtimeSettingsFlow.value = settings
                    homeViewModel.customCycle = settings.shiftCycle
                    calendarViewModel.customCycle = settings.shiftCycle
                    homeViewModel.selectTeam(settings.defaultTeamId)
                    calendarViewModel.setTeam(settings.defaultTeamId)
                }
            }
        }

        calendarSyncManager.startAutoSync()
        calendarSyncManager.requestPermissionsIfNeeded(requestCalendarPermissionsLauncher)

        setContent {
            val runtimeSettings by runtimeSettingsFlow.collectAsState()
            val syncError by calendarSyncManager.syncErrorFlow.collectAsState()
            val navController = rememberNavController()
            val scope = rememberCoroutineScope()
            var currentAlarmSettings by remember { mutableStateOf(AlarmSettings()) }

            LaunchedEffect(Unit) {
                settingsRepository.alarmSettingsFlow.collect { alarmSettings ->
                    currentAlarmSettings = alarmSettings
                }
            }

            // Auto-dismiss sync errors after 10 seconds
            LaunchedEffect(syncError) {
                if (syncError != null) {
                    kotlinx.coroutines.delay(10_000L)
                    calendarSyncManager.clearSyncError()
                }
            }

            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                Box(modifier = Modifier.fillMaxSize()) {
                    NavHost(
                        navController = navController,
                        startDestination = "main"
                    ) {
                    composable("main") {
                        val homeUiState by homeViewModel.uiState.collectAsState()
                        val calendarUiState by calendarViewModel.uiState.collectAsState()

                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState())
                                .padding(horizontal = 16.dp, vertical = 20.dp),
                            verticalArrangement = Arrangement.spacedBy(20.dp)
                        ) {
                            HomeScreen(
                                uiState = homeUiState,
                                onTeamSelected = { teamId ->
                                    homeViewModel.selectTeam(teamId)
                                    calendarViewModel.setTeam(teamId)
                                    if (runtimeSettings.defaultTeamId != teamId) {
                                        runtimeSettingsFlow.value =
                                            runtimeSettings.copy(defaultTeamId = teamId)
                                        scope.launch {
                                            settingsRepository.saveSettings(runtimeSettingsFlow.value)
                                        }
                                    }
                                },
                                modifier = Modifier
                            )
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "倒班助手",
                                    style = MaterialTheme.typography.headlineSmall
                                )
                                IconButton(
                                    onClick = { navController.navigate("settings") }
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.Settings,
                                        contentDescription = "设置"
                                    )
                                }
                            }
                            Text(
                                text = "倒班日历",
                                style = MaterialTheme.typography.headlineSmall
                            )
                            CalendarScreen(
                                uiState = calendarUiState,
                                onPreviousMonthClick = { calendarViewModel.goToPreviousMonth() },
                                onNextMonthClick = { calendarViewModel.goToNextMonth() },
                                onTodayClick = { calendarViewModel.goToToday() },
                                onStatsClick = { calendarViewModel.computeStats() },
                                onDismissStats = { calendarViewModel.dismissStats() }
                            )
                        }
                    }

                    composable("settings") {
                        val settingsViewModel: SettingsViewModel = viewModel(
                            factory = object : ViewModelProvider.Factory {
                                @Suppress("UNCHECKED_CAST")
                                override fun <T : androidx.lifecycle.ViewModel> create(
                                    modelClass: Class<T>
                                ): T {
                                    return SettingsViewModel(
                                        application,
                                        runtimeSettings,
                                        currentAlarmSettings,
                                        onSettingsSaved = { saved ->
                                            runtimeSettingsFlow.value = saved
                                            homeViewModel.customCycle = saved.shiftCycle
                                            calendarViewModel.customCycle = saved.shiftCycle
                                            homeViewModel.selectTeam(saved.defaultTeamId)
                                            calendarViewModel.setTeam(saved.defaultTeamId)
                                            scope.launch {
                                                settingsRepository.saveSettings(saved)
                                            }
                                            calendarSyncManager.syncFromCurrentState()
                                        },
                                        onAlarmSettingsChanged = { alarmSettings ->
                                            currentAlarmSettings = alarmSettings
                                            scope.launch {
                                                settingsRepository.saveAlarmSettings(alarmSettings)
                                            }
                                            calendarSyncManager.syncFromCurrentState()
                                        }
                                    ) as T
                                }
                            }
                        )
                        val settingsUiState by settingsViewModel.uiState.collectAsState()

                        SettingsScreen(
                            uiState = settingsUiState,
                            onUpdateCycleLength = { settingsViewModel.updateCycleLength(it) },
                            onSetDayShift = { idx, type -> settingsViewModel.setDayShift(idx, type) },
                            onSelectDefaultTeam = { settingsViewModel.selectDefaultTeam(it) },
                            onUpdateAlarmTime = { type, time ->
                                settingsViewModel.updateAlarmTime(type, time)
                            },
                            onSave = { settingsViewModel.save() },
                            onCancel = { settingsViewModel.cancel() },
                            onNavigateBack = { navController.popBackStack() }
                        )
                    }
                }

                    syncError?.let { error ->
                        Surface(
                            modifier = Modifier
                                .align(androidx.compose.ui.Alignment.BottomCenter)
                                .fillMaxWidth()
                                .padding(16.dp),
                            color = MaterialTheme.colorScheme.errorContainer,
                            shape = MaterialTheme.shapes.medium
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                            ) {
                                Text(
                                    text = error,
                                    color = MaterialTheme.colorScheme.onErrorContainer,
                                    style = MaterialTheme.typography.bodySmall,
                                    modifier = Modifier.weight(1f)
                                )
                                IconButton(
                                    onClick = { calendarSyncManager.clearSyncError() }
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.Close,
                                        contentDescription = "关闭",
                                        tint = MaterialTheme.colorScheme.onErrorContainer
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        homeViewModel.refreshToday()
        calendarViewModel.refresh()
        calendarSyncManager.syncFromCurrentState()
    }
}
