function Show-Menu {
	
     Write-Host "================ Menu ================"
    
     Write-Host "1: Press '1' for this option."
     Write-Host "2: Press '2' for this option."
     Write-Host "3: Press '3' for this option."
     Write-Host "Q: Press 'Q' to quit."
}

function Test-Function {

	$testvar = Read-Host -Prompt "Please enter a valid name"
	
	While ( $testvar -ne "Tom" -and $testvar -ne "q" ) {
	
		Write-Warning "Name not valid, please try again"
		$testvar = Read-Host -Prompt "Please enter a valid name"
	}
	
	If ( $testvar -eq "q" ) {
	
		Continue
	}
	
	Write-Output $testvar
}

function Another-Function {

	Param([parameter(mandatory=$true,position=0)]
		[string]
		$inputvalue
	)
	
	Write-Output $inputvalue
}

While ( $userinput -ne "q" ) {

    Show-Menu
	$userinput = Read-Host "Please make a selection"
     switch ($userinput)
     {
           '1' {
            
            'You chose option #1'
			$test = Test-Function
			Another-Function $test
			}
			
           'q' {
                Return
           }
     }
	Read-Host -Prompt "Press Enter to return to the main menu"
	clear
}