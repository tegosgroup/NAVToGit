function Convert-TextLanguage{
    param(
        [int]$languageId,
        [String]$content,
        [bool]$toNavision
    )
    try{
        if([String]::IsNullOrEmpty($content)){
            return [String]::Empty
        }
        if(-not (Is-LanguageDifferent -valueCulture $languageId)){
            return $content
        }
        [string]$searchDate = "    Date="
        [string]$searchTime = "    Time="
        #[string]$searchModified = "    Modified=Yes;\r\n"
        #[string]$searchVersion = "    Version List="
        [string]$lineEnd = "`r`n"

        #[bool]$modifiedContains = $content.IndexOf($searchModified, [System.StringComparison]::Ordinal) -ne -1

        [int]$indexSearchDate = $content.IndexOf($searchDate, [System.StringComparison]::Ordinal)
        [int]$indexDateEndLine = $content.IndexOf($lineEnd, $indexSearchDate, [System.StringComparison]::Ordinal)
        [string]$dateLine = $content.Substring($indexSearchDate, $indexDateEndLine - $indexSearchDate)

        [int]$indexSearchTime = $content.IndexOf($searchTime, [System.StringComparison]::Ordinal)
        [int]$indexTimeEndLine = $content.IndexOf($lineEnd, $indexSearchTime, [System.StringComparison]::Ordinal)
        [string]$timeLine = $content.Substring($indexSearchTime, $indexTimeEndLine - $indexSearchTime)

        [string]$tempObjectDate = $dateLine.Replace($searchDate, [String]::Empty).Replace("[", [String]::Empty).Replace("]", [String]::Empty).Replace(";", [String]::Empty)
        [string]$tempObjectTime = $timeLine.Replace($searchTime, [String]::Empty).Replace("[", [String]::Empty).Replace("]", [String]::Empty).Replace(";", [String]::Empty)

        if($toNavision){
            $tempObjectDate = Convert-ShortDateToSystem -lcid $languageId -value $tempObjectDate
            $tempObjectTime = Convert-LongTimeToSystem -valueCulture $languageId -value $tempObjectTime
        }else{
            $tempObjectDate = Convert-ShortDateFromSystem -lcid $languageId -value $tempObjectDate
            $tempObjectTime = Convert-LongTimeFromSystem -toCulture $languageId -value $tempObjectTime
        }

        [string]$newDateLine = $searchDate + $tempObjectDate + ';'
        [string]$newTimeLine = $searchTime + $tempObjectTime + ';'

        $content = $content.Replace($dateLine, $newDateLine)
        $content = $content.Replace($timeLine, $newTimeLine)

        <#[int]$indexSearchVersion = $content.IndexOf($searchVersion, [System.StringComparison]::Ordinal)
        [int]$indexVersionEndLine = $content.IndexOf($lineEnd, $indexSearchVersion, [System.StringComparison]::Ordinal)#>

        $content = Convert-NavDate -content $content -languageId $languageId -toNavision $toNavision
        $content = Convert-NavFieldProperty -content $content -propertyName "InitValue" -propertyType "Decimal" -languageId $languageId -toNavision $toNavision
        $content = Convert-NavFieldProperty -content $content -propertyName "MinValue" -propertyType "Decimal" -languageId $languageId -toNavision $toNavision
        $content = Convert-NavFieldProperty -content $content -propertyName "MaxValue" -propertyType "Decimal" -languageId $languageId -toNavision $toNavision
        $content = Convert-NavFieldProperty -content $content -propertyName "InitValue" -propertyType "Time" -languageId $languageId -toNavision $toNavision
        $content = Convert-NavFieldProperty -content $content -propertyName "MinValue" -propertyType "Time" -languageId $languageId -toNavision $toNavision
        $content = Convert-NavFieldProperty -content $content -propertyName "MaxValue" -propertyType "Time" -languageId $languageId -toNavision $toNavision

        return $content
    }catch{
        Write-Host $_
        return [String]::Empty
    }
}

function Is-LanguageDifferent{
    param(
        [int]$valueCulture
    )
    if($valueCulture -eq 0){
        return $False
    }
    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ciValue = [System.Globalization.CultureInfo]::new($valueCulture)
    if($ciCurr.LCID -eq $ciValue.LCID){
        return $False
    }
    return $True
}

function Convert-ShortDateToSystem{
    param(
        [int]$lcid,
        [string]$value
    )
    if($lcid -eq 0){
        return $value
    }
    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ci = [System.Globalization.CultureInfo]::new($lcid)

    if($ciCurr.LCID -eq $ci.LCID){
        return $value
    }

    [string]$currShortDate = Get-NavShortDateShort -valueCulture $ciCurr.LCID
    return [System.Convert]::ToDateTime($value, $ci.DateTimeFormat).ToString($currShortDate)
}

function Convert-LongTimeToSystem{
    param(
        [int]$valueCulture,
        [string]$value
    )
    if($valueCulture -eq 0){
        return $value
    }

    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ciValue = [System.Globalization.CultureInfo]::new($valueCulture)

    if($ciCurr.LCID -eq $ciValue.LCID){
        return $value
    }

    [string]$currLongTime = $ciCurr.DateTimeFormat.LongTimePattern
    [string]$time = [System.Convert]::ToDateTime($value, $ciValue.DateTimeFormat).ToString($currLongTime)

    if(($currLongTime.Contains("HH") -or $currLongTime.Contains("hh")) -and
    ($currLongTime.Contains("MM") -or $currLongTime.Contains("mm")) -and
    ($currLongTime.Contains("SS") -or $currLongTime.Contains("ss")) ){
        return $time
    }else{
        if($time.IndexOf(":") -eq 1){
            $time = "[ " + $time + "]"
            return $time
        }else{
            return $time
        }
    }

}

function Convert-ShortDateFromSystem{
    param(
        [int]$lcid,
        [string]$value
    )
    if($lcid -eq 0){
        return $value
    }
    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ci = [System.Globalization.CultureInfo]::new($lcid)
    if($ciCurr.LCID -eq $ci.LCID){
        return $value
    }

    [string]$toShortDate = Get-NavShortDateShort -valueCulture $ci.LCID
    [System.DateTime]$dt = [System.Convert]::ToDateTime($value, $ciCurr.DateTimeFormat)
    [string]$result = $dt.ToString($toShortDate,  [System.Globalization.CultureInfo]::InvariantCulture)
    return $result
}

function Convert-LongTimeFromSystem{
    param(
        [int]$toCulture,
        [string]$value
    )
    if($toCulture -eq 0){
        return $value
    }
    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ciTo = [System.Globalization.CultureInfo]::new($toCulture)

    if($ciCurr.LCID -eq $ciTo.LCID){
        return $value
    }

    [string]$toLongTime = $ciTo.DateTimeFormat.LongTimePattern
    [string]$time = [System.Convert]::ToDateTime($value, $ciCurr.DateTimeFormat).ToString($toLongTime, [System.Globalization.CultureInfo]::InvariantCulture)

    if(($toLongTime.Contains("HH") -or $toLongTime.Contains("hh")) -and
    ($toLongTime.Contains("MM") -or $toLongTime.Contains("mm")) -and
    ($toLongTime.Contains("SS") -or $toLongTime.Contains("ss"))){
        return $time
    }else{
        if($time.IndexOf(":") -eq 1){
            $time = "[ " + $time + "]"
            return $time
        }else{
            return $time
        }
    }
}

function Convert-NavDate{
    param(
        [string]$content,
        [int]$languageId,
        [bool]$toNavision
    )
    #[string]$regpattern = "(([\s]|[-]|[+]|[=]|[\(]|[\[]|[.]|[,])[0-9]{6,8}[D]([\s]|[;]|[\)]|[\]]|[.]|[,]))"
    [string]$regpattern = "[\s|\-|\+|\=|\(|\[|\.|\,]([0-9]{6,8}[D])(?=[\s|\;|\)|\]|\.|\,])"
    [string]$regpattern2 = "[0-9]{6,8}[D]"
    
    try{
        [System.Text.RegularExpressions.MatchCollection]$mc = [System.Text.RegularExpressions.Regex]::Matches($content, $regpattern)
        for([int]$i = 0; $i -lt $mc.Count; $i++){
            [System.Text.RegularExpressions.Match]$m = $mc[$i]
            [int]$hasCommentIndex = $m.Value.IndexOf("//")
            [System.Text.RegularExpressions.MatchCollection]$mc2 = [System.Text.RegularExpressions.Regex]::Matches($m.Value, $regpattern2)
            [bool]$isCommentOut = $False
            for([int]$j = 0; $j -lt $mc2.Count; $j++){
                [System.Text.RegularExpressions.Match] $m2 = $mc2[$j]
                if($m2.Value.StartsWith("0101")){
                    continue
                }
                if($hasCommentIndex -ne -1){
                    if($m2.Index -gt $hasCommentIndex){
                        $isCommentOut = $True
                    }
                }
                if($isCommentOut){
                    continue
                }

                [string]$value = $m2.Value.Replace("D", "")
                [string]$newValue = [string]::Empty

                if($toNavision){
                    $newValue = Convert-NavDateToSystem -lcid $languageId -value $value -isShortDate ($value.Length -eq 6)
                }else{
                    $newValue = Convert-NavDateFromSystem -lcid $languageId -value $value -isShortDate ($value.Length -eq 6)
                }

                if(-not ([String]::IsNullOrEmpty($newValue))){
                    $newValue = $m.Value.Replace($value, $newValue)
                    $content = $content.Remove($m.Index, $m.Length)
                    $content = $content.Insert($m.Index, $newValue)

                    $mc = [System.Text.RegularExpressions.Regex]::Matches($content, $regpattern)
                    $m = $mc[$i]
                    $mc2 = [System.Text.RegularExpressions.Regex]::Matches($m.Value, $regpattern2)
                }
            }
        }
    }catch{
        $test = $content.Substring(0,50)
        Write-Host "Fehler: $test"
    }
    return $content
}

function Convert-NavFieldProperty{
    param(
        [string]$content,
        [string]$propertyName,
        [string]$propertyType,
        [int]$languageId,
        [bool]$toNavision
    )
    [string]$regpattern = "(\s\s\s\s)(\{)(.*)(\;)(.*)(\;)(.*)(\;)(" + $propertyType + ")([^}]+)\}"
    [string]$regpattern2 = "(" + $propertyName + "=).*.*(.*;|.*})"

    try{
        [System.Text.RegularExpressions.MatchCollection]$mc = [System.Text.RegularExpressions.Regex]::Matches($content, $regpattern)
        for([int]$i = 0; $i -lt $mc.Count; $i++){
            [System.Text.RegularExpressions.Match]$m = $mc[$i]
            [System.Text.RegularExpressions.MatchCollection]$mc2 = [System.Text.RegularExpressions.Regex]::Matches($m.Value, $regpattern2)

            for([int]$j = 0; $j -lt $mc2.Count; $j++){
                [System.Text.RegularExpressions.Match]$m2 = $mc2[$j]
                [string]$searchProperty = $propertyName + "="
                [string]$value = $m2.Value.Substring($m2.Value.IndexOf($searchProperty) + $searchProperty.Length, $m2.Value.Length - $m2.Value.IndexOf($searchProperty) - $searchProperty.Length).Replace("}", "").Replace(";", "").TrimStart(' ').TrimEnd(' ')
                [string]$newValue = [System.String]::Empty

                switch($propertyType.ToUpper()){
                    "DECIMAL" {
                        if($toNavision){
                            $newValue = Convert-NavDecimalToSystem -lcid $languageId -value $value
                        }else{
                            $newValue = Convert-NavDecimalFromSystem -lcid $languageId -value $value
                        }
                        break
                    }
                    "TIME" {
                        [string]$checkValue = $value.Replace("[", [System.String]::Empty).Replace("]", [System.String]::Empty)
                        if($toNavision){
                            $newValue = Convert-LongTimeToSystem -valueCulture $languageId -value $checkValue
                        }else{
                            $newValue = Convert-LongTimeFromSystem -toCulture $languageId -value $checkValue
                        }
                        break
                    }
                    default {
                        break
                    }
                }
                if(-not ([System.String]::IsNullOrEmpty($newValue))){
                    $newValue = $mc2.Value.Replace($value, $newValue)
                    $content = $content.Remove($m.Index + $m2.Index, $m2.Length)
                    $content = $content.Insert($m.Index + $m2.Index, $newValue)

                    $mc = [System.Text.RegularExpressions.Regex]::Matches($content, $regpattern)
                    $m = $mc[$i]
                    $mc2 = [System.Text.RegularExpressions.Regex]::Matches($m.Value, $regpattern2)
                }
            }
        }
    }catch{

    }

    return $content

}

function Get-NavShortDateShort{
    param(
        [int]$valueCulture
    )
    [string]$shortDate = Get-NavShortDate -valueCulture $valueCulture
    $shortDate = $shortDate.Replace("YYYY", "YY").Replace("yyyy", "yy")
    return $shortDate
}
function Get-NavShortDate{
    param(
        [int]$valueCulture
    )
    [System.Globalization.CultureInfo]$ci = [System.Globalization.CultureInfo]::new($valueCulture)

    [string]$shortDate = $ci.DateTimeFormat.ShortDatePattern
    if(-not ($shortDate.Contains("MM")) -and $shortDate.Contains("M")){
        $shortDate = $shortDate.Replace("M", "MM")
    }
    if(-not ($shortDate.Contains("mm")) -and $shortDate.Contains("m")){
        $shortDate = $shortDate.Replace("m", "mm")
    }
    if(-not ($shortDate.Contains("DD")) -and $shortDate.Contains("D")){
        $shortDate = $shortDate.Replace("D", "DD");
    }
    if(-not ($shortDate.Contains("dd")) -and $shortDate.Contains("d")){
        $shortDate = $shortDate.Replace("d", "dd")
    }

    return $shortDate
}

function Convert-NavDateToSystem{
    param(
        [int]$lcid,
        [string]$value,
        [bool]$isShortDate
    )
    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ci = [System.Globalization.CultureInfo]::new($lcid)

    if($ciCurr.LCID -eq $ci.LCID){
        return $value
    }

    [string]$currShortDate = [String]::Empty
    [string]$fromShortDate = [String]::Empty

    if($isShortDate){
        $currShortDate = Get-NavShortDateShort -valueCulture $ciCurr.LCID
        $currShortDate = $currShortDate.Replace("/", "")
        $currShortDate = $currShortDate.Replace(".", "")
        #eventuell "-" Replacen
        $fromShortDate = Get-NavShortDateShort -valueCulture $ci.LCID
        $fromShortDate = $fromShortDate.Replace("/", "")
        $fromShortDate = $fromShortDate.Replace(".", "")
    }else{
        $currShortDate = Get-NavShortDate -valueCulture $ciCurr.LCID
        $currShortDate = $currShortDate.Replace("/", "")
        $currShortDate = $currShortDate.Replace(".", "")

        $fromShortDate = Get-NavShortDate -valueCulture $ci.LCID
        $fromShortDate = $fromShortDate.Replace("/", "")
        $fromShortDate = $fromShortDate.Replace(".", "")
    }

    [System.DateTime]$dt = [System.DateTime]::ParseExact($value, $fromShortDate, $ci)
    return $dt.ToString($currShortDate)
}

function Convert-NavDateFromSystem{
    param(
        [int]$lcid,
        [string]$value,
        [bool]$isShortDate
    )
    if($lcid -eq 0){
        return $value
    }

    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ci = [System.Globalization.CultureInfo]::new($lcid)

    if($ciCurr.LCID -eq $ci.LCID){
        return $value
    }
    
    [string]$currShortDate =[String]::Empty
    [string]$toShortDate = [String]::Empty

    if($isShortDate){
        $currShortDate = Get-NavShortDateShort -valueCulture $ciCurr.LCID
        $currShortDate = $currShortDate.Replace("/", "")
        $currShortDate = $currShortDate.Replace(".", "")
        $currShortDate = $currShortDate.Replace("-", "")

        $toShortDate = Get-NavShortDateShort -valueCulture $ci.LCID
        $toShortDate = $toShortDate.Replace("/", "")
        $toShortDate = $toShortDate.Replace(".", "")
        $toShortDate = $toShortDate.Replace("-", "")
    }else{
        $currShortDate = Get-NavShortDate -valueCulture $ciCurr.LCID
        $currShortDate = $currShortDate.Replace("/", "")
        $currShortDate = $currShortDate.Replace(".", "")
        $currShortDate = $currShortDate.Replace("-", "")

        $toShortDate = Get-NavShortDate -valueCulture $ci.LCID
        $toShortDate = $toShortDate.Replace("/", "")
        $toShortDate = $toShortDate.Replace(".", "")
        $toShortDate = $toShortDate.Replace("-", "")
    }

    [System.DateTime]$dt = [System.DateTime]::ParseExact($value, $currShortDate, $ciCurr)
    return $dt.ToString($toShortDate)
}

function Convert-NavDecimalToSystem{
    param(
        [int]$lcid,
        [string]$value
    )
    if($lcid -eq 0){
        return $value
    }

    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ci = [System.Globalization.CultureInfo]::new($lcid)

    if($ciCurr.LCID -eq $ci.LICD){
        return $value
    }

    [Decimal]$newvalue = [Decimal]::Parse($value, $ci)
    return $newvalue.ToString([System.String]::Empty, $ciCurr)
}

function Convert-NavDecimalFromSystem{
    param(
        [int]$lcid,
        [string]$value
    )
    
    if($lcid -eq 0){
        return $value
    }

    [System.Globalization.CultureInfo]$ciCurr = [System.Globalization.CultureInfo]::CurrentCulture
    [System.Globalization.CultureInfo]$ci = [System.Globalization.CultureInfo]::new($lcid)

    if($ciCurr.LCID -eq $ci.LICD){
        return $value
    }

    [Decimal]$newvalue = [Decimal]::Parse($value, $ciCurr)
    return $newvalue.ToString([System.String]::Empty, $ci)

}

<#$folder="C:\temp\ChangedObjectsDe"

$folder= Get-ChildItem $folder -File -Recurse
        foreach ($object in $folder) {        
            $newFolder = "C:\temp\ChangedObjectsEn\$object"    
            $contentPath = $Object.FullName
            $content = [System.IO.File]::ReadAllText($contentPath,[System.Text.Encoding]::GetEncoding(850))
            [System.IO.File]::WriteAllText($newFolder,(Convert-TextLanguage -languageId 1033 -content $content -toNavision $false),[System.Text.Encoding]::GetEncoding(850))
        }#>