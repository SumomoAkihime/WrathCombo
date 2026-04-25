param(
    [string]$SourcePath = "WrathCombo/Resources/Localization/Presets/CustomComboPresets.resx",
    [string]$OutputPath = "WrathCombo/Resources/Localization/Presets/CustomComboPresets.zh-Hans.resx"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-Utf8Xml {
    param([string]$Path)

    $xml = New-Object System.Xml.XmlDocument
    $xml.PreserveWhitespace = $true
    $xml.LoadXml([System.IO.File]::ReadAllText((Resolve-Path $Path), [System.Text.Encoding]::UTF8))
    return $xml
}

function Convert-PresetLine {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $Line
    }

    $exactMap = @{
        "Simple Mode - Single Target" = "简易模式 - 单体"
        "Advanced Mode - Single Target" = "进阶模式 - 单体"
        "Simple Mode - AoE" = "简易模式 - 群体"
        "Advanced Mode - AoE" = "进阶模式 - 群体"
        "Simple DPS Mode - Single Target" = "简易输出模式 - 单体"
        "Advanced DPS Mode - Single Target" = "进阶输出模式 - 单体"
        "Simple DPS Mode - AoE" = "简易输出模式 - 群体"
        "Advanced DPS Mode - AoE" = "进阶输出模式 - 群体"
        "Simple Healing Mode - Single Target" = "简易治疗模式 - 单体"
        "Advanced Healing Mode - Single Target" = "进阶治疗模式 - 单体"
        "Simple Healing Mode - AoE" = "简易治疗模式 - 群体"
        "Advanced Healing Mode - AoE" = "进阶治疗模式 - 群体"
        "Mitigation Feature - Single Target" = "减伤功能 - 单体"
        "Mitigation Feature - AoE" = "减伤功能 - 群体"
        "Retargeting Features" = "重定向功能"
        "Boss Raidwide Options" = "Boss 团伤选项"
        "Conflicts with:" = "冲突项："
        "General" = "通用"
        "Normal" = "普通"
        "Content" = "内容"
        "Roles and Content" = "职能与内容"
        "Job Roles" = "职能分类"
        "Role Actions" = "职能动作"
        "DOL" = "采集职业"
        "Variant" = "异闻"
        "Variant Dungeons" = "异闻迷宫"
        "Raise" = "复活"
        "Or" = "或"
        "Bozja" = "博兹雅"
        "Occult Crescent" = "秘术新月"
        "Setting" = "设置"
        "Replaces" = "替换"
    }

    if ($exactMap.ContainsKey($Line)) {
        return $exactMap[$Line]
    }

    if ($Line -eq "This is the ideal option for newcomers to the job.") {
        return "这是该职业新手的理想选项。"
    }

    if ($Line -eq "Can be Retargeted with the Retargeting Features below.") {
        return "可以通过下方的重定向功能进行重定向。"
    }

    if ($Line -eq "Each action can be Retargeted with the Retargeting Features below.") {
        return "每个动作都可以通过下方的重定向功能进行重定向。"
    }

    if ($Line -eq "Solace can be Retargeted with the Retargeting Features below.") {
        return "Solace 可以通过下方的重定向功能进行重定向。"
    }

    if ($Line -eq "Collection of Options to Retarget Manually-Used Single Target Heals.") {
        return "用于重定向手动使用的单体治疗技能的选项集合。"
    }

    if ($Line -eq "Collection of cooldowns and spell features on Holy/Holy III.") {
        return "整合到 Holy/Holy III 上的冷却与技能功能集合。"
    }

    if ($Line -eq "Collection of cooldowns and spell features on Glares/Stones/Aeros/Dia.") {
        return "整合到 Glares/Stones/Aeros/Dia 上的冷却与技能功能集合。"
    }

    if ($Line -eq "Particularly with autorotation.") {
        return "尤其适合配合自动循环使用。"
    }

    if ($Line -eq "This is the ideal option for newcomers to the job. Particularly with autorotation.") {
        return "这是该职业新手的理想选项，尤其适合配合自动循环使用。"
    }

    if ($Line -match '^Replaces (?<action>.+?) with a full one-button (?<body>.+?)\.$') {
        $action = $Matches["action"]
        $body = $Matches["body"]
        $bodyMap = @{
            "single target rotation" = "完整的一键单体循环"
            "AoE rotation" = "完整的一键群体循环"
            "single target healing utility" = "完整的一键单体治疗功能"
            "AoE healing utility" = "完整的一键群体治疗功能"
            "single target rotation, including automatic dps card assignment" = "完整的一键单体循环，并包含自动输出卡分配"
            "AoE rotation, including automatic dps card assignment" = "完整的一键群体循环，并包含自动输出卡分配"
        }

        if ($bodyMap.ContainsKey($body)) {
            return "将 $action 替换为$($bodyMap[$body])。"
        }
    }

    if ($Line -match '^Replaces (?<action>.+?) with a one button (?<body>.+?)\.$') {
        $action = $Matches["action"]
        $body = $Matches["body"]
        $bodyMap = @{
            "single target healing setup" = "一键单体治疗方案"
            "AoE healing setup" = "一键群体治疗方案"
        }

        if ($bodyMap.ContainsKey($body)) {
            return "将 $action 替换为$($bodyMap[$body])。"
        }
    }

    if ($Line -match '^Replaces (?<action>.+?) with options below\.?$') {
        return "将 $($Matches['action']) 替换为下方选项集合。"
    }

    $globalMap = [ordered]@{
        "Conflicts with:" = "冲突项："
        "Simple Mode - Single Target" = "简易模式 - 单体"
        "Advanced Mode - Single Target" = "进阶模式 - 单体"
        "Simple Mode - AoE" = "简易模式 - 群体"
        "Advanced Mode - AoE" = "进阶模式 - 群体"
        "Simple DPS Mode - Single Target" = "简易输出模式 - 单体"
        "Advanced DPS Mode - Single Target" = "进阶输出模式 - 单体"
        "Simple DPS Mode - AoE" = "简易输出模式 - 群体"
        "Advanced DPS Mode - AoE" = "进阶输出模式 - 群体"
        "Simple Healing Mode - Single Target" = "简易治疗模式 - 单体"
        "Advanced Healing Mode - Single Target" = "进阶治疗模式 - 单体"
        "Simple Healing Mode - AoE" = "简易治疗模式 - 群体"
        "Advanced Healing Mode - AoE" = "进阶治疗模式 - 群体"
        "Mitigation Feature - Single Target" = "减伤功能 - 单体"
        "Mitigation Feature - AoE" = "减伤功能 - 群体"
        "Retargeting Features" = "重定向功能"
        "Boss Raidwide Options" = "Boss 团伤选项"
        "This is the ideal option for newcomers to the job." = "这是该职业新手的理想选项。"
        "Particularly with autorotation." = "尤其适合配合自动循环使用。"
    }

    $translated = $Line
    foreach ($entry in $globalMap.GetEnumerator()) {
        $translated = $translated.Replace($entry.Key, $entry.Value)
    }

    return $translated
}

$sourceXml = Read-Utf8Xml -Path $SourcePath
$outputXml = Read-Utf8Xml -Path $SourcePath

foreach ($node in @($outputXml.root.data)) {
    $valueNode = $node.SelectSingleNode("value")
    if ($null -eq $valueNode) {
        continue
    }

    $lines = $valueNode.InnerText -split "`r?`n", 0
    $translatedLines = foreach ($line in $lines) {
        Convert-PresetLine -Line $line
    }

    $valueNode.InnerText = [string]::Join([Environment]::NewLine, $translatedLines)
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path ".").Path + "\" + $OutputPath.Replace('/', '\'), $outputXml.OuterXml, $utf8NoBom)


