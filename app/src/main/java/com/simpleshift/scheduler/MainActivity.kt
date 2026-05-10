package com.simpleshift.scheduler

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
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
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.simpleshift.scheduler.calendar.CalendarEventManager
import com.simpleshift.scheduler.data.repository.SettingsRepository
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.CalendarEventIds
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.ui.calendar.CalendarScreen
import com.simpleshift.scheduler.ui.home.HomeScreen
import com.simpleshift.scheduler.ui.settings.SettingsScreen
import com.simpleshift.scheduler.viewmodel.CalendarViewModel
import com.simpleshift.scheduler.viewmodel.HomeViewModel
import com.simpleshift.scheduler.viewmodel.SettingsViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val homeViewModel: HomeViewModel by viewModels()
    private val calendarViewModel: CalendarViewModel by viewModels()
    private lateinit var settingsRepository: SettingsRepository
    private lateinit var calendarEventManager: CalendarEventManager
    private val runtimeSettingsFlow = MutableStateFlow(RuntimeShiftSettings())

    private val requestCalendarPermissionsLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (permissions.any { it.value == true }) {
            lifecycleScope.launch {
                syncCalendarEventsFromCurrentState()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        settingsRepository = SettingsRepository(applicationContext)
        calendarEventManager = CalendarEventManager(this)

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

        lifecycleScope.launch {
            combine(
                settingsRepository.settingsFlow,
                settingsRepository.alarmSettingsFlow,
                settingsRepository.calendarEventIdsFlow
            ) { shiftSettings, alarmSettings, eventIds ->
                Triple(shiftSettings, alarmSettings, eventIds)
            }.collect { (shiftSettings, alarmSettings, eventIds) ->
                if (shiftSettings.isValid && hasCalendarPermissions()) {
                    syncCalendarEvents(alarmSettings, shiftSettings, eventIds)
                }
            }
        }

        requestCalendarPermissionsIfNeeded()

        setContent {
            val runtimeSettings by runtimeSettingsFlow.collectAsState()
            val navController = rememberNavController()
            val scope = rememberCoroutineScope()
            var currentAlarmSettings by remember { mutableStateOf(AlarmSettings()) }

            LaunchedEffect(Unit) {
                settingsRepository.alarmSettingsFlow.collect { alarmSettings ->
                    currentAlarmSettings = alarmSettings
                }
            }

            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
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
                                            syncCalendarEventsFromCurrentState()
                                        },
                                        onAlarmSettingsChanged = { alarmSettings ->
                                            currentAlarmSettings = alarmSettings
                                            scope.launch {
                                                settingsRepository.saveAlarmSettings(alarmSettings)
                                            }
                                            syncCalendarEventsFromCurrentState()
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
            }
        }
    }

    override fun onResume() {
        super.onResume()
        homeViewModel.refreshToday()
        calendarViewModel.refresh()
        if (hasCalendarPermissions()) {
            syncCalendarEventsFromCurrentState()
        }
    }

    private fun hasCalendarPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, Manifest.permission.WRITE_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.READ_CALENDAR
            ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCalendarPermissionsIfNeeded() {
        if (!hasCalendarPermissions()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestCalendarPermissionsLauncher.launch(
                    arrayOf(
                        Manifest.permission.READ_CALENDAR,
                        Manifest.permission.WRITE_CALENDAR
                    )
                )
            }
        }
    }

    private fun syncCalendarEventsFromCurrentState() {
        lifecycleScope.launch {
            try {
                val shiftSettings = runtimeSettingsFlow.value
                val alarmSettings = settingsRepository.alarmSettingsFlow.first()
                val eventIds = settingsRepository.calendarEventIdsFlow.first()
                if (shiftSettings.isValid) {
                    syncCalendarEvents(alarmSettings, shiftSettings, eventIds)
                }
            } catch (_: Exception) {}
        }
    }

    private fun syncCalendarEvents(
        alarmSettings: AlarmSettings,
        shiftSettings: RuntimeShiftSettings,
        eventIds: CalendarEventIds
    ) {
        if (!shiftSettings.isValid) return
        val phaseOffset = (shiftSettings.defaultTeamId - 1) *
            (shiftSettings.shiftCycle.size / Team.TOTAL_TEAMS)
        val newEventIds = calendarEventManager.syncNextSevenDays(
            alarmSettings, shiftSettings.shiftCycle, phaseOffset, eventIds
        )
        lifecycleScope.launch {
            settingsRepository.saveCalendarEventIds(newEventIds)
        }
    }
}
