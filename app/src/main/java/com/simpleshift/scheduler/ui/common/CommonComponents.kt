package com.simpleshift.scheduler.ui.common

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.util.TeamNameMapper

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TeamDropdown(
    selectedTeamId: Int,
    availableTeams: List<Team>,
    onTeamSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var expanded by remember { mutableStateOf(false) }
    val selectedTeam = availableTeams.find { it.id == selectedTeamId }
        ?: availableTeams.first()

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it }
    ) {
        OutlinedTextField(
            value = TeamNameMapper.toName(selectedTeam.id, context),
            onValueChange = {},
            readOnly = true,
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = modifier.menuAnchor().fillMaxWidth()
        )
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            availableTeams.forEach { team ->
                DropdownMenuItem(
                    text = { Text(TeamNameMapper.toName(team.id, context)) },
                    onClick = {
                        expanded = false
                        onTeamSelected(team.id)
                    }
                )
            }
        }
    }
}
