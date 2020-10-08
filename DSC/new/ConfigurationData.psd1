@{
    AllNodes = @(
        @{
            NodeName    = 'ContosoDc'
            Role        = @('Domain_Controller')
        },

        @{
            NodeName    = 'AdminPc'
            SamiraASmbScriptLocation = [string]'C:\ScheduledTasks\SamiraASmbSimulation.ps1'
            Role        = @('Domain_Member','Admin')
        },

        @{
            NodeName    = 'Client01'
            Role        = @('Domain_Member','Client')
        },

        @{
            NodeName    = 'VictimPc'
            Role        = @('Domain_Member','Victim')
        }
    )
}