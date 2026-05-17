package com.simpleshift.scheduler

import android.os.Bundle
import androidx.glance.appwidget.updateAll
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
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
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
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.simpleshift.scheduler.calendar.CalendarEventManager
import com.simpleshift.scheduler.widget.ShiftWidget
import com.simpleshift.scheduler.calendar.CalendarSyncManager
import com.simpleshift.scheduler.data.repository.SettingsRepository
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.SalaryConfig
import com.simpleshift.scheduler.ui.calendar.CalendarScreen
import com.simpleshift.scheduler.ui.home.HomeScreen
import com.simpleshift.scheduler.ui.home.NewHomeScreen
import com.simpleshift.scheduler.ui.home.NewHomeScreenV2
import com.simpleshift.scheduler.ui.home.NewHomeScreenV3
import com.simpleshift.scheduler.ui.home.NewHomeScreenV4
import com.simpleshift.scheduler.ui.profile.ProfileScreen
import com.simpleshift.scheduler.ui.colleague_mode.ColleagueModeScreen
import com.simpleshift.scheduler.ui.leave_optimizer.LeaveOptimizerScreen
import com.simpleshift.scheduler.ui.salary_predictor.SalaryPredictorScreen
import com.simpleshift.scheduler.ui.settings.AlarmSettingsScreen
import com.simpleshift.scheduler.ui.settings.SettingsScreen
import com.simpleshift.scheduler.ui.settings.ShiftRuleEditorScreen
import com.simpleshift.scheduler.ui.theme.ShiftSchedulerTheme
import com.simpleshift.scheduler.util.cleanupOldShareImages
import com.simpleshift.scheduler.viewmodel.AlarmSettingsViewModel
import com.simpleshift.scheduler.viewmodel.CalendarViewModel
import com.simpleshift.scheduler.viewmodel.ColleagueModeViewModel
import com.simpleshift.scheduler.viewmodel.HomeViewModel
import com.simpleshift.scheduler.viewmodel.LeaveOptimizerViewModel
import com.simpleshift.scheduler.viewmodel.SalaryPredictorViewModel
import com.simpleshift.scheduler.viewmodel.SettingsViewModel
import com.simpleshift.scheduler.viewmodel.ShiftRuleViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    companion object {
        private const val USE_NEW_HOME = true
        private const val USE_NEW_HOME_V2 = true
        private const val USE_NEW_HOME_V3 = true
        private const val USE_NEW_HOME_V4 = true
        private const val USE_NEW_SETTINGS = true
    }

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

        cleanupOldShareImages()

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
                    homeViewModel.customReferenceDate = settings.referenceDate
                    calendarViewModel.customCycle = settings.shiftCycle
                    calendarViewModel.customReferenceDate = settings.referenceDate
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
            var currentSalaryConfig by remember { mutableStateOf(SalaryConfig()) }

            LaunchedEffect(Unit) {
                settingsRepository.alarmSettingsFlow.collect { alarmSettings ->
                    currentAlarmSettings = alarmSettings
                    homeViewModel.updateAlarmSettings(alarmSettings)
                }
            }

            LaunchedEffect(Unit) {
                settingsRepository.salaryConfigFlow.collect { config ->
                    currentSalaryConfig = config
                }
            }

            // Auto-dismiss sync errors after 10 seconds
            LaunchedEffect(syncError) {
                if (syncError != null) {
                    kotlinx.coroutines.delay(10_000L)
                    calendarSyncManager.clearSyncError()
                }
            }

            if (USE_NEW_HOME_V2) {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentRoute = navBackStackEntry?.destination?.route
                val bottomNavRoutes = listOf("home", "calendar", "profile")

                ShiftSchedulerTheme {
                    androidx.compose.material3.Scaffold(
                        bottomBar = {
                            if (currentRoute in bottomNavRoutes) {
                                NavigationBar {
                                    NavigationBarItem(
                                        selected = currentRoute == "home",
                                        onClick = {
                                            navController.navigate("home") {
                                                popUpTo("home") { inclusive = true }
                                            }
                                        },
                                        icon = { Icon(Icons.Filled.Home, contentDescription = "首页") },
                                        label = { Text("首页") }
                                    )
                                    NavigationBarItem(
                                        selected = currentRoute == "calendar",
                                        onClick = {
                                            navController.navigate("calendar") {
                                                popUpTo("home") { inclusive = true }
                                            }
                                        },
                                        icon = { Icon(Icons.Filled.DateRange, contentDescription = "日历") },
                                        label = { Text("日历") }
                                    )
                                    NavigationBarItem(
                                        selected = currentRoute == "profile",
                                        onClick = {
                                            navController.navigate("profile") {
                                                popUpTo("home") { inclusive = true }
                                            }
                                        },
                                        icon = { Icon(Icons.Filled.Person, contentDescription = "我的") },
                                        label = { Text("我的") }
                                    )
                                }
                            }
                        }
                    ) { paddingValues ->
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(paddingValues)
                        ) {
                            NavHost(
                                navController = navController,
                                startDestination = "home"
                            ) {
                                composable("home") {
                                    val homeUiState by homeViewModel.uiState.collectAsState()

                                    if (USE_NEW_HOME_V4) {
                                        NewHomeScreenV4(
                                            uiState = homeUiState,
                                            onLeaveOptimizerClick = { navController.navigate("leave_optimizer") },
                                            onColleagueModeClick = { navController.navigate("colleague_mode") },
                                            onSalaryPredictorClick = { navController.navigate("salary_predictor") }
                                        )
                                    } else if (USE_NEW_HOME_V3) {
                                        NewHomeScreenV3(
                                            uiState = homeUiState,
                                            onLeaveOptimizerClick = { navController.navigate("leave_optimizer") },
                                            onColleagueModeClick = { navController.navigate("colleague_mode") },
                                            onSalaryPredictorClick = { navController.navigate("salary_predictor") }
                                        )
                                    } else {
                                        NewHomeScreenV2(
                                            uiState = homeUiState
                                        )
                                    }
                                }

                                composable("calendar") {
                                    val calendarUiState by calendarViewModel.uiState.collectAsState()

                                    val onCalendarTeamSelected: (Int) -> Unit = { teamId ->
                                        homeViewModel.selectTeam(teamId)
                                        calendarViewModel.setTeam(teamId)
                                        if (runtimeSettings.defaultTeamId != teamId) {
                                            runtimeSettingsFlow.value =
                                                runtimeSettings.copy(defaultTeamId = teamId)
                                            scope.launch {
                                                settingsRepository.saveSettings(runtimeSettingsFlow.value)
                                            }
                                        }
                                    }

                                    CalendarScreen(
                                        uiState = calendarUiState,
                                        onPreviousMonthClick = { calendarViewModel.goToPreviousMonth() },
                                        onNextMonthClick = { calendarViewModel.goToNextMonth() },
                                        onTodayClick = { calendarViewModel.goToToday() },
                                        onStatsClick = { calendarViewModel.computeStats() },
                                        onNavigateBack = { navController.popBackStack() },
                                        onTeamSelected = onCalendarTeamSelected,
                                        availableTeams = com.simpleshift.scheduler.domain.model.Team.ALL_TEAMS
                                    )
                                }

                                composable("profile") {
                                    val homeUiState by homeViewModel.uiState.collectAsState()

                                    val onProfileTeamSelected: (Int) -> Unit = { teamId ->
                                        homeViewModel.selectTeam(teamId)
                                        calendarViewModel.setTeam(teamId)
                                        if (runtimeSettings.defaultTeamId != teamId) {
                                            runtimeSettingsFlow.value =
                                                runtimeSettings.copy(defaultTeamId = teamId)
                                            scope.launch {
                                                settingsRepository.saveSettings(runtimeSettingsFlow.value)
                                            }
                                        }
                                    }

                                    ProfileScreen(
                                        selectedTeamId = homeUiState.selectedTeamId,
                                        availableTeams = homeUiState.availableTeams,
                                        onTeamSelected = onProfileTeamSelected,
                                        onRulesClick = {
                                            if (USE_NEW_SETTINGS) navController.navigate("shift_rule_editor")
                                            else navController.navigate("settings")
                                        },
                                        onAlarmClick = {
                                            if (USE_NEW_SETTINGS) navController.navigate("alarm_settings")
                                            else navController.navigate("settings")
                                        },
                                        onLeaveOptimizerClick = {
                                            navController.navigate("leave_optimizer")
                                        },
                                        onColleagueModeClick = {
                                            navController.navigate("colleague_mode")
                                        },
                                        onSalaryPredictorClick = {
                                            navController.navigate("salary_predictor")
                                        }
                                    )
                                }

                                composable("shift_rule_editor") {
                                    val shiftRuleViewModel: ShiftRuleViewModel = viewModel(
                                        factory = object : ViewModelProvider.Factory {
                                            @Suppress("UNCHECKED_CAST")
                                            override fun <T : androidx.lifecycle.ViewModel> create(
                                                modelClass: Class<T>
                                            ): T {
                                                return ShiftRuleViewModel(
                                                    application,
                                                    runtimeSettings,
                                                    onSettingsSaved = { saved ->
                                                        runtimeSettingsFlow.value = saved
                                                        homeViewModel.customCycle = saved.shiftCycle
                                                        homeViewModel.customReferenceDate = saved.referenceDate
                                                        calendarViewModel.customCycle = saved.shiftCycle
                                                        calendarViewModel.customReferenceDate = saved.referenceDate
                                                        homeViewModel.selectTeam(saved.defaultTeamId)
                                                        calendarViewModel.setTeam(saved.defaultTeamId)
                                                        scope.launch {
                                                            settingsRepository.saveSettings(saved)
                                                        }
                                                        calendarSyncManager.syncFromCurrentState()
                                                        notifyWidgetUpdate()
                                                    }
                                                ) as T
                                            }
                                        }
                                    )
                                    val shiftRuleUiState by shiftRuleViewModel.uiState.collectAsState()

                                    ShiftRuleEditorScreen(
                                        uiState = shiftRuleUiState,
                                        onAddToSequence = { shiftRuleViewModel.addToSequence(it) },
                                        onRemoveFromSequence = { shiftRuleViewModel.removeFromSequence(it) },
                                        onGoToStep2 = { shiftRuleViewModel.goToStep2() },
                                        onGoBackToStep1 = { shiftRuleViewModel.goBackToStep1() },
                                        onSetStartDate = { shiftRuleViewModel.setStartDate(it) },
                                        onSetHasEndDate = { shiftRuleViewModel.setHasEndDate(it) },
                                        onSetEndDate = { shiftRuleViewModel.setEndDate(it) },
                                        onSetDefaultTeam = { shiftRuleViewModel.setDefaultTeam(it) },
                                        onSave = { shiftRuleViewModel.save() },
                                        onNavigateBack = { navController.popBackStack() }
                                    )
                                }

                                composable("alarm_settings") {
                                    val alarmViewModel: AlarmSettingsViewModel = viewModel(
                                        factory = object : ViewModelProvider.Factory {
                                            @Suppress("UNCHECKED_CAST")
                                            override fun <T : androidx.lifecycle.ViewModel> create(
                                                modelClass: Class<T>
                                            ): T {
                                                return AlarmSettingsViewModel(
                                                    application,
                                                    currentAlarmSettings,
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
                                    val alarmUiState by alarmViewModel.uiState.collectAsState()

                                    AlarmSettingsScreen(
                                        alarmSettings = alarmUiState.alarmSettings,
                                        onUpdateAlarmTime = { type, time ->
                                            alarmViewModel.updateAlarmTime(type, time)
                                        },
                                        onNavigateBack = { navController.popBackStack() }
                                    )
                                }

                                composable("leave_optimizer") {
                                    val leaveOptimizerViewModel: LeaveOptimizerViewModel = viewModel(
                                        factory = object : ViewModelProvider.Factory {
                                            @Suppress("UNCHECKED_CAST")
                                            override fun <T : androidx.lifecycle.ViewModel> create(
                                                modelClass: Class<T>
                                            ): T {
                                                return LeaveOptimizerViewModel(application) as T
                                            }
                                        }
                                    )
                                    val leaveUiState by leaveOptimizerViewModel.uiState.collectAsState()

                                    LaunchedEffect(runtimeSettings) {
                                        leaveOptimizerViewModel.refresh(
                                            customCycle = runtimeSettings.shiftCycle,
                                            referenceDate = runtimeSettings.referenceDate,
                                            teamId = runtimeSettings.defaultTeamId
                                        )
                                    }

                                    LeaveOptimizerScreen(
                                        uiState = leaveUiState,
                                        onNavigateBack = { navController.popBackStack() },
                                        onMaxLeaveDaysChanged = { days ->
                                            leaveOptimizerViewModel.setMaxLeaveDays(days)
                                        }
                                    )
                                }

                                composable("colleague_mode") {
                                    val colleagueModeViewModel: ColleagueModeViewModel = viewModel(
                                        factory = object : ViewModelProvider.Factory {
                                            @Suppress("UNCHECKED_CAST")
                                            override fun <T : androidx.lifecycle.ViewModel> create(
                                                modelClass: Class<T>
                                            ): T {
                                                return ColleagueModeViewModel(application) as T
                                            }
                                        }
                                    )
                                    val colleagueUiState by colleagueModeViewModel.uiState.collectAsState()

                                    LaunchedEffect(runtimeSettings) {
                                        // Set default team A to user's current team
                                        colleagueModeViewModel.refresh(
                                            customCycle = runtimeSettings.shiftCycle,
                                            referenceDate = runtimeSettings.referenceDate
                                        )
                                    }

                                    ColleagueModeScreen(
                                        uiState = colleagueUiState,
                                        availableTeams = com.simpleshift.scheduler.domain.model.Team.ALL_TEAMS,
                                        onTeamASelected = { colleagueModeViewModel.setTeamA(it) },
                                        onTeamBSelected = { colleagueModeViewModel.setTeamB(it) },
                                        onSwapTeams = { colleagueModeViewModel.swapTeams() },
                                        onNavigateBack = { navController.popBackStack() },
                                        onShareClick = { activity -> colleagueModeViewModel.startShare(activity) },
                                        onShareComplete = { colleagueModeViewModel.onShareComplete() },
                                        onClearShareError = { colleagueModeViewModel.clearShareError() }
                                    )
                                }

                                composable("salary_predictor") {
                                    val salaryViewModel: SalaryPredictorViewModel = viewModel(
                                        factory = object : ViewModelProvider.Factory {
                                            @Suppress("UNCHECKED_CAST")
                                            override fun <T : androidx.lifecycle.ViewModel> create(
                                                modelClass: Class<T>
                                            ): T {
                                                return SalaryPredictorViewModel(application) as T
                                            }
                                        }
                                    )
                                    val salaryUiState by salaryViewModel.uiState.collectAsState()

                                    LaunchedEffect(runtimeSettings) {
                                        salaryViewModel.refresh(
                                            customCycle = runtimeSettings.shiftCycle,
                                            referenceDate = runtimeSettings.referenceDate,
                                            teamId = runtimeSettings.defaultTeamId,
                                            salaryConfig = currentSalaryConfig
                                        )
                                    }

                                    SalaryPredictorScreen(
                                        uiState = salaryUiState,
                                        availableTeams = com.simpleshift.scheduler.domain.model.Team.ALL_TEAMS,
                                        onNavigateBack = { navController.popBackStack() },
                                        onConfigUpdate = { newPremiums ->
                                            salaryViewModel.updateConfig(SalaryConfig(newPremiums))
                                        },
                                        onTeamSelected = { teamId ->
                                            salaryViewModel.setTeam(teamId)
                                        },
                                        onMonthChange = { yearMonth ->
                                            salaryViewModel.setMonth(yearMonth)
                                        },
                                        onExtraShiftsCountChange = { count ->
                                            salaryViewModel.setExtraShiftsCount(count)
                                        },
                                        onExtraShiftTypeChange = { type ->
                                            salaryViewModel.setExtraShiftType(type)
                                        },
                                        onToggleSettingsExpanded = {
                                            salaryViewModel.toggleSettingsExpanded()
                                        }
                                    )
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
                                                        notifyWidgetUpdate()
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
            } else {
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

                            Column(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .verticalScroll(rememberScrollState())
                                    .padding(horizontal = 16.dp, vertical = 20.dp),
                                verticalArrangement = Arrangement.spacedBy(20.dp)
                            ) {
                                val onTeamSelected: (Int) -> Unit = { teamId ->
                                    homeViewModel.selectTeam(teamId)
                                    calendarViewModel.setTeam(teamId)
                                    if (runtimeSettings.defaultTeamId != teamId) {
                                        runtimeSettingsFlow.value =
                                            runtimeSettings.copy(defaultTeamId = teamId)
                                        scope.launch {
                                            settingsRepository.saveSettings(runtimeSettingsFlow.value)
                                        }
                                    }
                                }

                                if (USE_NEW_HOME) {
                                    NewHomeScreen(
                                        uiState = homeUiState,
                                        onTeamSelected = onTeamSelected,
                                        onCalendarClick = { navController.navigate("calendar") },
                                        onSettingsClick = { navController.navigate("settings") }
                                    )
                                } else {
                                    HomeScreen(
                                        uiState = homeUiState,
                                        onTeamSelected = onTeamSelected,
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
                                }
                            }
                        }

                        composable("calendar") {
                            val calendarUiState by calendarViewModel.uiState.collectAsState()

                            val onCalendarTeamSelected: (Int) -> Unit = { teamId ->
                                homeViewModel.selectTeam(teamId)
                                calendarViewModel.setTeam(teamId)
                                if (runtimeSettings.defaultTeamId != teamId) {
                                    runtimeSettingsFlow.value =
                                        runtimeSettings.copy(defaultTeamId = teamId)
                                    scope.launch {
                                        settingsRepository.saveSettings(runtimeSettingsFlow.value)
                                    }
                                }
                            }

                            CalendarScreen(
                                uiState = calendarUiState,
                                onPreviousMonthClick = { calendarViewModel.goToPreviousMonth() },
                                onNextMonthClick = { calendarViewModel.goToNextMonth() },
                                onTodayClick = { calendarViewModel.goToToday() },
                                onStatsClick = { calendarViewModel.computeStats() },
                                onNavigateBack = { navController.popBackStack() },
                                onTeamSelected = onCalendarTeamSelected,
                                availableTeams = com.simpleshift.scheduler.domain.model.Team.ALL_TEAMS
                            )
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
                                                notifyWidgetUpdate()
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
    }

    override fun onResume() {
        super.onResume()
        homeViewModel.refreshToday()
        calendarViewModel.refresh()
        calendarSyncManager.syncFromCurrentState()
        notifyWidgetUpdate()
    }

    private fun notifyWidgetUpdate() {
        lifecycleScope.launch {
            try {
                ShiftWidget().updateAll(this@MainActivity)
            } catch (_: Exception) {}
        }
    }
}
