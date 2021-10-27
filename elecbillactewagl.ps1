$path2sourcefile = "C:\Temp\25.csv"
$objReading = @()
$objShoulder = @()
$objPeak = @()
$objOffpeak = @()
$objSolar = @()
$objDate = @()

$OFFPEAK = 0.22
$PEAK = 0.37
$SHOULDER = 0.26
$FEEDIN = 0.08

$totalOffPeak = 0
$totalShoulder = 0
$totalPeak = 0
$totalSolar = 0

if (Test-Path($path2sourcefile))
{
        if ((Get-item $path2sourcefile).Length -gt 2KB)
        {
            try
            { 
                $file = Get-Content $path2sourcefile
                $csvContent = $file[5..($file.Length-1)]   #Get content after the first 5 lines 
                $objReading = $csvContent | ConvertFrom-Csv -Delimiter ','
                $objDate = $objReading.'Reading Date' | Sort-Object | Get-Unique #Get the list of dates 
     
            }
            Catch {  Write-Host "Something wrong with $path2CSVfile " -foregroundcolor "red" }
        }
        Else 
        {
            Write-Host "Double check file $path2sourcefile" -foregroundcolor "red"
            Exit
        }

}
else { 
    Write-host "Cannot find $path2sourcefile"
    exit
}

Foreach($day in $objDate)
{
    $objOffpeak1d = @()
    $objShoulder1d = @()
    $objPeak1d = @() 
    $objSolar1d = @() 
    $totalOffPeak1d = 0
    $totalShoulder1d = 0
    $totalPeak1d = 0
    $totalSolar1d = 0
    $sum1d = 0
    $cost1d = 0
    $counterSolar1d = 0

    Foreach($obj in $objReading)
    {
        if($day -match $obj.'Reading Date')
        {

            if($obj.'Register Description' -like "Solar")
            {
                $objSolar1d += $obj
        
            }
        
            if($obj.'Register Description' -like "Offpeak")
            {
                $objOffpeak1d += $obj
        
            }
            if($obj.'Register Description' -like "Shoulder")
            {
                $objShoulder1d += $obj
        
            } 
        
            if($obj.'Register Description' -like "Peak")
            {
                $objPeak1d += $obj
        
            } 

        }
        
    }

    Foreach($object1d in $objSolar1d) {
           
        $counterSolar1d = $object1d.Units
        $totalSolar1d += $counterSolar1d   
            
    }  
    
    Foreach( $obj1d in $objOffpeak1d) {
        $cancelout15m = 0
        Foreach($object1d in $objSolar1d) {
            if (($object1d.'Reading Start Time' -eq $obj1d.'Reading Start Time') -and ($object1d.'Reading Date' -eq $obj1d.'Reading Date'))
            {
                $cancelout15m = $object1d.Units - $obj1d.Units
                if ($cancelout15m -gt 0)
                {
                    $diffOffPeak1d = $cancelout15m*$FEEDIN
                }
                else {
    
                    $diffOffPeak1d = $cancelout15m*$OFFPEAK
                }
    
            }
    
        }  
            $totalOffPeak1d += $diffOffPeak1d    
    }
    
    Foreach( $obj1d in $objShoulder1d) {
        $cancelout15m = 0
        Foreach($object1d in $objSolar1d) {
            if (($object1d.'Reading Start Time' -eq $obj1d.'Reading Start Time') -and ($object1d.'Reading Date' -eq $obj1d.'Reading Date'))
            {
                $cancelout15m = $object1d.Units - $obj1d.Units
                if ($cancelout15m -gt 0)
                {
                    $diffShoulder1d = $cancelout15m*$FEEDIN
                }
                else {
    
                    $diffShoulder1d = $cancelout15m*$SHOULDER
                }
        
            }
    
        }  
            $totalShoulder1d += $diffShoulder1d   
    }
    
    Foreach( $obj1d in $objPeak1d) {
        $cancelout15m = 0
        Foreach($object1d in $objSolar1d) {
            if (($object1d.'Reading Start Time' -eq $obj1d.'Reading Start Time') -and ($object1d.'Reading Date' -eq $obj1d.'Reading Date'))
            {
                $cancelout15m = $object1d.Units - $obj1d.Units
                if ($cancelout15m -gt 0)
                {
                    $diffPeak1d = $cancelout15m*$FEEDIN
                }
                else {
    
                    $diffPeak1d = $cancelout15m*$PEAK
                }
        
            }
    
        }  
            $totalPeak1d += $diffPeak1d   
    }

    $feedinsolar1d = [math]::Round($totalSolar1d, 2)
    Write-host "Cost/Income analysis on $day"
    Write-host "Total feed-in solar (Kwh):" $feedinsolar1d

    $sum1d = [math]::Round(($totalPeak1d + $totalShoulder1d + $totalOffPeak1d), 2)

    if($sum1d -lt 0)
    {
            $cost1d = [Math]::Abs($sum1d)
            Write-host "Cost($):" $cost1d -ForegroundColor Red

    }
    else 
    {
            Write-host "Income:"$sum1d -ForegroundColor Blue
    }

    $totalSolar += $totalSolar1d
    $totalOffPeak += $totalOffPeak1d
    $totalShoulder += $totalShoulder1d
    $totalPeak += $totalPeak1d

}    
        
if($objDate.Count -gt 1) 
{
    $from = $objDate[0]
    $to = $objDate[$objDate.Length -1]   
}
else
{
    $from = $objDate
    $to = $objDate
}
    
$feedinsolar = [math]::Round($totalSolar, 2)
Write-host "`nCost/Income analysis from $from to $to" -ForegroundColor Yellow
Write-host "Total feed-in solar (Kwh):" $feedinsolar -ForegroundColor Yellow

$sum = [math]::Round(($totalPeak + $totalShoulder + $totalOffPeak), 2)

if($sum -lt 0)
{
        $cost = [Math]::Abs($sum)
        Write-host "Cost($):" $cost -ForegroundColor Red

}
else 
{
        Write-host "Income:"$sum -ForegroundColor Blue
}

