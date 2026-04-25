param(
    [string]$SourcePath = "WrathCombo/Resources/Localization/Presets/CustomComboPresets.resx",
    [string]$OutputPath = "WrathCombo/Resources/Localization/Presets/CustomComboPresets.zh-Hans.resx",
    [string]$ActionMapPath = "tools/huiji-action-map.json"
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

function Read-ActionNameMap {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return [ordered]@{}
    }

    $jsonText = [System.IO.File]::ReadAllText((Resolve-Path $Path), [System.Text.Encoding]::UTF8)
    $json = $jsonText | ConvertFrom-Json
    if ($null -eq $json.by_en) {
        return [ordered]@{}
    }

    $map = [ordered]@{}
    $entries = @($json.by_en.PSObject.Properties | Sort-Object { $_.Name.Length } -Descending)
    foreach ($entry in $entries) {
        if ([string]::IsNullOrWhiteSpace($entry.Name) -or [string]::IsNullOrWhiteSpace([string]$entry.Value)) {
            continue
        }
        $map[[string]$entry.Name] = [string]$entry.Value
    }

    return $map
}

function Convert-PresetLine {
    param(
        [string]$Line,
        [hashtable]$ActionNameMap
    )

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
        "Burst Mode" = "爆发模式"
        "Basic Combo" = "基础连招"
        "AoE Basic Combo" = "群体基础连招"
        "One-Button Mitigation Feature" = "一键减伤功能"
        "One-Button Party Mitigation Feature" = "一键团辅减伤功能"
        "Advanced Mitigation Options" = "进阶减伤选项"
        "Boss Encounter Mitigation" = "Boss 战减伤"
        "Non Boss Encounter Mitigation" = "非 Boss 战减伤"
        "Combo Heals Option" = "连招治疗选项"
        "Damage skills on Main Combo" = "主连招输出技能"
        "Collection of Damage skills on main combo." = "主连招上的输出技能集合。"
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
    $manualActionMap = [ordered]@{
        "Hard Slash" = "重斩"
        "Lucid Dreaming" = "醒梦"
        "Second Wind" = "内丹"
        "Bloodbath" = "浴血"
        "Interject" = "插言"
        "Addle" = "昏乱"
        "Reprisal" = "雪仇"
        "Swiftcast" = "即刻咏唱"
        "Esuna" = "康复"
        "Rampart" = "铁壁"
        "Low Blow" = "下踢"
        "Arms Length" = "亲疏自行"
        "Divination" = "占卜"
        "Lightspeed" = "光速"
        "Fan Dance" = "扇舞"
        "Fan Dance 3" = "扇舞·急"
        "Fan Dance 4" = "扇舞·终"
        "Arm's Length" = "亲疏自行"
        "Leg Sweep" = "扫腿"
        "Interrupt" = "打断"
        "Fight or Flight" = "战逃反应"
    }
    $replaceWholePhrase = {
        param(
            [string]$InputText,
            [string]$Needle,
            [string]$Replacement
        )

        if ([string]::IsNullOrWhiteSpace($Needle)) {
            return $InputText
        }

        $pattern = '(?<![A-Za-z])' + [regex]::Escape($Needle) + '(?![A-Za-z])'
        return [regex]::Replace($InputText, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{
            param($match)
            $Replacement
        })
    }

    $translateFragment = {
        param([string]$Text)

        $result = $Text
        foreach ($entry in $manualActionMap.GetEnumerator()) {
            if ($result.Contains([string]$entry.Key)) {
                $result = & $replaceWholePhrase $result ([string]$entry.Key) ([string]$entry.Value)
            }
        }

        foreach ($entry in $ActionNameMap.GetEnumerator()) {
            if ($result.Contains([string]$entry.Key)) {
                $result = & $replaceWholePhrase $result ([string]$entry.Key) ([string]$entry.Value)
            }
        }

        $result = $result.Replace("Role Action ", "职能动作 ")
        $result = $result.Replace("Defensive Role Action ", "防御职能动作 ")
        $result = $result.Replace("Raidwide ", "团伤 ")
        $result = $result.Replace("Tankbuster ", "死刑 ")
        $result = $result.Replace("Variant ", "异闻 ")
        return $result
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

    if ($Line -eq "Use Aetherflow when out of Aetherflow stacks.") {
        return "在没有 Aetherflow 层数时使用 Aetherflow。"
    }

    if ($Line -eq "Collection of tools designed to try and cast during a raidwide attack when detected.") {
        return "用于在检测到团伤攻击时尝试施放的工具集合。"
    }

    if ($Line -eq "This will work for most, but not all raidwide attacks and is no substitute for learning the fight") {
        return "它适用于大多数但并非全部团伤机制，不能替代熟悉战斗本身。"
    }

    if ($Line -eq "Options for Advanced Combos' In-Combo Mitigation.") {
        return "进阶连招内置减伤的选项集合。"
    }

    if ($Line -eq "Enable Mitigation in each Advanced Combo to use these options.") {
        return "需要先在各个进阶连招中启用减伤，才会使用这些选项。"
    }

    if ($Line -eq "(Simple Mode does not use these Options, instead Recommended Values in place of them)") {
        return "（简易模式不会使用这些选项，而是改用对应的推荐值逻辑。）"
    }

    if ($Line -eq "Enable this to add Variant Actions in Variant Dungeons.") {
        return "启用后会在异闻迷宫中加入异闻技能。"
    }

    if ($Line -eq "Variant Actions will be used by Single Target and AoE DPS Combos, in both Simple & Advanced") {
        return "这些异闻技能会用于单体与群体输出连招，并同时覆盖简易与进阶模式。"
    }

    if ($Line -eq "- Requires target's HP to be under:") {
        return "- 需要目标生命值低于："
    }

    if ($Line -eq "- Prefers to use during Fight or Flight.") {
        return "- 优先在战逃反应期间使用。"
    }

    if ($Line -eq "These features are ideal if you want to customize the rotation.") {
        return "如果你想自定义循环，这些功能会很适合你。"
    }

    if ($Line -eq "Override Smaller Features") {
        return "覆盖较小功能"
    }

    if ($Line -eq "This option adds the Bard's Songs to the Advanced Bard Feature.") {
        return "此选项会把吟游诗人的歌曲加入进阶吟游功能。"
    }

    if ($Line -eq "Options for including Fan Dance 3 and 4 into the rotation.") {
        return "将扇舞·急与扇舞·终纳入循环的选项。"
    }

    if ($Line -eq "Fan Dance Proc Options") {
        return "扇舞触发选项"
    }

    if ($Line -match "(?s)^Change custom actions into dance steps while dancing\.\r?\nLets you still dance with combos on, without using Standard Step Combo Features above\.$") {
        return "在跳舞期间将自定义动作替换为舞步。`n这样即使开启连招功能，也仍然可以跳舞，而无需启用上方的标准舞步连招功能。"
    }

    if ($Line -eq "Features and options involving shared role actions for Healers.") {
        return "与治疗职能共享职能动作相关的功能与选项。"
    }

    if ($Line -eq "Features and options involving shared role actions for Tanks.") {
        return "与坦克职能共享职能动作相关的功能与选项。"
    }

    if ($Line -eq "Features and options involving shared role actions for Melee DPS.") {
        return "与近战输出共享职能动作相关的功能与选项。"
    }

    if ($Line -eq "Features and options involving shared role actions for Physical Ranged DPS.") {
        return "与物理远程输出共享职能动作相关的功能与选项。"
    }

    if ($Line -eq "Features and options involving shared role actions for Magical Ranged DPS.") {
        return "与魔法远程输出共享职能动作相关的功能与选项。"
    }

    if ($Line -eq "Adds Interject to the rotation when your target's cast is interruptible.") {
        return "当目标读条可打断时，将插言加入循环。"
    }

    if ($Line -eq "Adds Lucid Dreaming when MP drops below slider value:") {
        return "当 MP 低于滑条设定值时加入醒梦："
    }

    if ($Line -match '(?s)^Collection of tools designed to try and cast during a raidwide attack when detected\.\r?\nThis will work for most, but not all raidwide attacks and is no substitute for learning the fight$') {
        return "用于在检测到团伤攻击时尝试施放的工具集合。`n它适用于大多数但并非全部团伤机制，不能替代熟悉战斗本身。"
    }

    if ($Line -match "(?s)^Options for Advanced Combos' In-Combo Mitigation\.\r?\nEnable Mitigation in each Advanced Combo to use these options\.\r?\n\(Simple Mode does not use these Options, instead Recommended Values in place of them\)$") {
        return "进阶连招内置减伤的选项集合。`n需要先在各个进阶连招中启用减伤，才会使用这些选项。`n（简易模式不会使用这些选项，而是改用对应的推荐值逻辑。）"
    }

    if ($Line -match '(?s)^Enable this to add Variant Actions in Variant Dungeons\.\r?\nVariant Actions will be used by Single Target and AoE DPS Combos, in both Simple & Advanced$') {
        return "启用后会在异闻迷宫中加入异闻技能。`n这些异闻技能会用于单体与群体输出连招，并同时覆盖简易与进阶模式。"
    }

    if ($Line -eq "Include Target's Target") {
        return "包含目标的目标"
    }

    if ($Line -eq "Particularly with autorotation.") {
        return "尤其适合配合自动循环使用。"
    }

    if ($Line -eq "This is the ideal option for newcomers to the job. Particularly with autorotation.") {
        return "这是该职业新手的理想选项，尤其适合配合自动循环使用。"
    }

    if ($Line -match '^Replaces (?<action>.+?) with a full one-button (?<body>.+?)\.$') {
        $action = & $translateFragment $Matches["action"]
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
        $action = & $translateFragment $Matches["action"]
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
        return "将 $(& $translateFragment $Matches['action']) 替换为下方选项集合。"
    }

    if ($Line -match '^(?<name>.+?) Option$') {
        return "$(& $translateFragment $Matches['name']) 选项"
    }

    if ($Line -match '^(?<name>.+?) Feature$') {
        return "$(& $translateFragment $Matches['name']) 功能"
    }

    if ($Line -match '^(?<name>.+?) Retargeting$') {
        return "$(& $translateFragment $Matches['name']) 重定向"
    }

    if ($Line -match '^Retarget (?<name>.+)$') {
        return "重定向 $(& $translateFragment $Matches['name'])"
    }

    if ($Line -match '^Global (?<name>.+?) Features$') {
        return "全局 $(& $translateFragment $Matches['name']) 功能"
    }

    if ($Line -match '^(?<name>.+?): (?<body>.+?) Protection$') {
        return "$(& $translateFragment $Matches['name'])：$(& $translateFragment $Matches['body']) 防重复"
    }

    if ($Line -match '^Adds (?<name>.+?) to Burst Mode\.?$') {
        return "将 $(& $translateFragment $Matches['name']) 加入爆发模式。"
    }

    if ($Line -match '^Adds (?<name>.+?) to the rotation\.?$') {
        return "将 $(& $translateFragment $Matches['name']) 加入循环。"
    }

    if ($Line -match '^Adds (?<name>.+?) to the combo\.?$') {
        return "将 $(& $translateFragment $Matches['name']) 加入连招。"
    }

    if ($Line -match '^Adds (?<name>.+?) when [Rr]aidwide is detected casting\.$') {
        return "检测到团伤读条时加入 $(& $translateFragment $Matches['name'])。"
    }

    if ($Line -match '^Adds (?<name>.+?) when raidwide casting is detected\.$') {
        return "检测到团伤读条时加入 $(& $translateFragment $Matches['name'])。"
    }

    if ($Line -match '^Adds (?<name>.+?) when target non-boss is casting\.$') {
        return "当非 Boss 目标正在读条时加入 $(& $translateFragment $Matches['name'])。"
    }

    if ($Line -match "^Adds (?<name>.+?) to the rotation when your target is casting\.$") {
        return "当目标正在读条时，将 $(& $translateFragment $Matches['name']) 加入循环。"
    }

    if ($Line -match '^Adds the Balance opener at level (?<level>\d+)\.$') {
        return "在等级 $($Matches['level']) 时加入 Balance 起手。"
    }

    if ($Line -match '^Balance Opener \(Level (?<level>\d+)\)$') {
        return "Balance 起手（等级 $($Matches['level'])）"
    }

    if ($Line -match '^Use (?<name>.+?) on cooldown\.$') {
        return "$(& $translateFragment $Matches['name']) 冷却好就使用。"
    }

    if ($Line -match '^Use (?<name>.+?) when HP is below set threshold\.$') {
        return "生命值低于设定阈值时使用 $(& $translateFragment $Matches['name'])。"
    }

    if ($Line -match '^Use (?<name>.+?) on incapacitated party members\.$') {
        return "对无法战斗的队友使用 $(& $translateFragment $Matches['name'])。"
    }

    if ($Line -match '^Uses (?<name>.+?) when available at or below set health threshold\.$') {
        return "当 $(& $translateFragment $Matches['name']) 可用且生命值低于设定阈值时使用。"
    }

    if ($Line -match '^Adds (?<name>.+?) to Burst Mode below selected health$') {
        return "在低于设定生命值时，将 $(& $translateFragment $Matches['name']) 加入爆发模式。"
    }

    if ($Line -match '^Adds Defensive Role Action (?<name>.+?) to Burst Mode below selected health$') {
        return "在低于设定生命值时，将防御职能动作 $(& $translateFragment $Matches['name']) 加入爆发模式。"
    }

    if ($Line -match '^Adds (?<name>.+?) when (?<count>\d+) or more targets\.$') {
        return "当目标数达到 $($Matches['count']) 个或更多时加入 $(& $translateFragment $Matches['name'])。"
    }

    if ($Line -match '^Adds (?<name>.+?) to the one-button mitigation\.$') {
        return "将 $(& $translateFragment $Matches['name']) 加入一键减伤功能。"
    }

    if ($Line -match '^Adds (?<name>.+?) and (?<name2>.+?) to the rotation\.$') {
        return "将 $(& $translateFragment $Matches['name']) 和 $(& $translateFragment $Matches['name2']) 加入循环。"
    }

    if ($Line -match '^Adds (?<name>.+?) and (?<name2>.+?) to the combo, using them when below the HP Percentage threshold\.$') {
        return "将 $(& $translateFragment $Matches['name']) 和 $(& $translateFragment $Matches['name2']) 加入连招，并在生命百分比低于阈值时使用。"
    }

    if ($Line -match "^Adds (?<name>.+?) to the rotation when your target's cast is interruptible\.$") {
        return "当目标读条可打断时，将 $(& $translateFragment $Matches['name']) 加入循环。"
    }

    if ($Line -match "(?s)^Adds (?<name>.+?) to the rotation when your target is casting\.\r?\n(?<rest>.+)$") {
        return "当目标正在读条时，将 $(& $translateFragment $Matches['name']) 加入循环。`n$($Matches['rest'])"
    }

    if ($Line -match '^Will Retarget the Raises affected here to your Heal Stack\.$') {
        return "会将此处涉及的复活技能重定向到你的治疗目标栈。"
    }

    if ($Line -match '^Applies Esuna to your target if there is a cleansable debuff\.$') {
        return "若目标身上有可驱散减益，则对其施放 Esuna。"
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
        "Burst Mode" = "爆发模式"
        "Basic Combo" = "基础连招"
        "AoE Basic Combo" = "群体基础连招"
        "One-Button Mitigation Feature" = "一键减伤功能"
        "One-Button Party Mitigation Feature" = "一键团辅减伤功能"
        "Advanced Mitigation Options" = "进阶减伤选项"
        "Boss Encounter Mitigation" = "Boss 战减伤"
        "Non Boss Encounter Mitigation" = "非 Boss 战减伤"
        "Combo Heals Option" = "连招治疗选项"
        "Damage skills on Main Combo" = "主连招输出技能"
        "Collection of Damage skills on main combo." = "主连招上的输出技能集合。"
        "Role Action " = "职能动作 "
        "Raidwide " = "团伤 "
        "Tankbuster " = "死刑 "
        "Variant " = "异闻 "
        "Alternative Raise 功能" = "备用复活功能"
        "This is the ideal option for newcomers to the job." = "这是该职业新手的理想选项。"
        "Particularly with autorotation." = "尤其适合配合自动循环使用。"
    }
    $translated = $Line
    foreach ($entry in $globalMap.GetEnumerator()) {
        $translated = $translated.Replace($entry.Key, $entry.Value)
    }

    foreach ($entry in $manualActionMap.GetEnumerator()) {
        if ($translated.Contains([string]$entry.Key)) {
            $translated = & $replaceWholePhrase $translated ([string]$entry.Key) ([string]$entry.Value)
        }
    }

    foreach ($entry in $ActionNameMap.GetEnumerator()) {
        if ($translated.Contains([string]$entry.Key)) {
            $translated = & $replaceWholePhrase $translated ([string]$entry.Key) ([string]$entry.Value)
        }
    }

    $translated = $translated.Replace("Role Action ", "职能动作 ")
    $translated = $translated.Replace("Defensive Role Action ", "防御职能动作 ")
    $translated = $translated.Replace("Raidwide ", "团伤 ")
    $translated = $translated.Replace("Tankbuster ", "死刑 ")
    $translated = $translated.Replace("Variant ", "异闻 ")
    $translated = $translated.Replace("Alternative Raise 功能", "备用复活功能")

    return $translated
}

$sourceXml = Read-Utf8Xml -Path $SourcePath
$outputXml = Read-Utf8Xml -Path $SourcePath
$actionNameMap = Read-ActionNameMap -Path $ActionMapPath

foreach ($node in @($outputXml.root.data)) {
    $valueNode = $node.SelectSingleNode("value")
    if ($null -eq $valueNode) {
        continue
    }

    $lines = $valueNode.InnerText -split "`r?`n", 0
    $translatedLines = foreach ($line in $lines) {
        Convert-PresetLine -Line $line -ActionNameMap $actionNameMap
    }

    $valueNode.InnerText = [string]::Join([Environment]::NewLine, $translatedLines)
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path ".").Path + "\" + $OutputPath.Replace('/', '\'), $outputXml.OuterXml, $utf8NoBom)
