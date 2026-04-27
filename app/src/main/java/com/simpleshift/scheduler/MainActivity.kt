package com.simpleshift.scheduler

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.simpleshift.scheduler.data.repository.SettingsRepository
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
    private val runtimeSettingsFlow = MutableStateFlow(RuntimeShiftSettings())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        settingsRepository = SettingsRepository(applicationContext)

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

        setContent {
            val runtimeSettings by runtimeSettingsFlow.collectAsState()
            val navController = rememberNavController()
            val scope = rememberCoroutineScope()

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
                            Button(
                                onClick = { navController.navigate("settings") }
                            ) {
                                Text("设置")
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
                                        onSettingsSaved = { saved ->
                                            runtimeSettingsFlow.value = saved
                                            homeViewModel.customCycle = saved.shiftCycle
                                            calendarViewModel.customCycle = saved.shiftCycle
                                            homeViewModel.selectTeam(saved.defaultTeamId)
                                            calendarViewModel.setTeam(saved.defaultTeamId)
                                            scope.launch {
                                                settingsRepository.saveSettings(saved)
                                            }
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
    }
}
