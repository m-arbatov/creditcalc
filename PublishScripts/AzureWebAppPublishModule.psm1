#  AzureWebAppPublishModule.psm1 — это модуль скрипта Windows PowerShell. Он экспортирует функции Windows PowerShell, которые автоматизируют управление жизненным циклом для веб-приложений. Вы можете использовать эти функции как есть или настроить для своего приложения и среды публикации.





Set-StrictMode -Version 3

# Переменная для сохранения исходной подписки.
$Script:originalCurrentSubscription = $null

# Переменная для сохранения исходной учетной записи хранения.
$Script:originalCurrentStorageAccount = $null

# Переменная для сохранения учетной записи хранения указанной пользователем подписки.
$Script:originalStorageAccountOfUserSpecifiedSubscription = $null

# Переменная для сохранения имени подписки.
$Script:userSpecifiedSubscription = $null

# Номер порта веб-развертывания
New-Variable -Name WebDeployPort -Value 8172 -Option Constant

<#
.SYNOPSIS
Добавляет дату и время в начало сообщения.

.DESCRIPTION
Добавляет дату и время в начало сообщения. Эта функция предназначена для сообщений, записываемых в потоки Error и Verbose.

.PARAMETER  Message
Указывает сообщение без даты.

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Format-DevTestMessageWithTime -Message "Добавление файла $filename в каталог"
2/5/2014 1:03:08 PM - Добавление файла $filename в каталог

.LINK
Write-VerboseWithTime

.LINK
Write-ErrorWithTime
#>
function Format-DevTestMessageWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    return ((Get-Date -Format G)  + ' - ' + $Message)
}


<#

.SYNOPSIS
Записывает сообщение об ошибке с текущим временем в префиксе.

.DESCRIPTION
Записывает сообщение об ошибке с текущим временем в префиксе. Эта функция вызывает функцию Format-DevTestMessageWithTime для добавления времени перед записью сообщения в поток Error.

.PARAMETER  Message
Указывает сообщение в вызове сообщения об ошибке. Строку сообщения можно передать в функцию.

.INPUTS
System.String

.OUTPUTS
Нет. Функция выполняет запись в поток Error.

.EXAMPLE
PS C:> Write-ErrorWithTime -Message "Failed. Cannot find the file."

Write-Error: 2/6/2014 8:37:29 AM - Failed. Cannot find the file.
 + CategoryInfo     : NotSpecified: (:) [Write-Error], WriteErrorException
 + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException

.LINK
Write-Error

#>
function Write-ErrorWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Error
}


<#
.SYNOPSIS
Записывает подробное сообщение с текущим временем в префиксе.

.DESCRIPTION
Записывает подробное сообщение с текущим временем в префиксе. Поскольку вызывается функция Write-Verbose, сообщение выводится только при выполнении скрипта с параметром Verbose или с заданным для параметра VerbosePreference значением Continue.

.PARAMETER  Message
Указывает сообщение в вызове подробного сообщения. Строку сообщения можно передать в функцию.

.INPUTS
System.String

.OUTPUTS
Нет. Функция выполняет запись в поток Verbose.

.EXAMPLE
PS C:> Write-VerboseWithTime -Message "The operation succeeded."
PS C:>
PS C:\> Write-VerboseWithTime -Message "The operation succeeded." -Verbose
VERBOSE: 1/27/2014 11:02:37 AM - The operation succeeded.

.EXAMPLE
PS C:\ps-test> "The operation succeeded." | Write-VerboseWithTime -Verbose
VERBOSE: 1/27/2014 11:01:38 AM - The operation succeeded.

.LINK
Write-Verbose
#>
function Write-VerboseWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Verbose
}


<#
.SYNOPSIS
Записывает сообщение узла с текущим временем в префиксе.

.DESCRIPTION
Эта функция записывает в основную программу (Write-Host) сообщение с текущим временем в префиксе. Результат записи в основную программу варьируется. Большинство программ, использующих Windows PowerShell, записывают эти сообщения в стандартный вывод.

.PARAMETER  Message
Указывает базовое сообщение без даты. Строку сообщения можно передать в функцию.

.INPUTS
System.String

.OUTPUTS
Нет. Функция записывает сообщение в основную программу.

.EXAMPLE
PS C:> Write-HostWithTime -Message "Операция выполнена успешно."
1/27/2014 11:02:37 AM - Операция выполнена успешно.

.LINK
Write-Host
#>
function Write-HostWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )
    
    if ((Get-Variable SendHostMessagesToOutput -Scope Global -ErrorAction SilentlyContinue) -and $Global:SendHostMessagesToOutput)
    {
        if (!(Get-Variable -Scope Global AzureWebAppPublishOutput -ErrorAction SilentlyContinue) -or !$Global:AzureWebAppPublishOutput)
        {
            New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
        }

        $Global:AzureWebAppPublishOutput += $Message | Format-DevTestMessageWithTime
    }
    else 
    {
        $Message | Format-DevTestMessageWithTime | Write-Host
    }
}


<#
.SYNOPSIS
Возвращает значение $true, если свойство метода является членом объекта. В противном случае — $false.

.DESCRIPTION
Возвращает $true, если свойство или метод является членом объекта. Эта функция возвращает $false для статических методов класса и для представлений, таких как PSBase и PSObject.

.PARAMETER  Object
Указывает объект в тесте. Введите переменную, которая содержит объект или выражение, возвращающее объект. Указывать типы, такие как [DateTime], или передавать объекты в эту функцию невозможно.

.PARAMETER  Member
Указывает имя свойства или метода в тесте. При указании метода опустите скобки после имени метода.

.INPUTS
Нет. Эта функция не получает входные данные из конвейера.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Test-Member -Object (Get-Date) -Member DayOfWeek
True

.EXAMPLE
PS C:\> $date = Get-Date
PS C:\> Test-Member -Object $date -Member AddDays
True

.EXAMPLE
PS C:\> [DateTime]::IsLeapYear((Get-Date).Year)
True
PS C:\> Test-Member -Object (Get-Date) -Member IsLeapYear
False

.LINK
Get-Member
#>
function Test-Member
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [String]
        $Member
    )

    return $null -ne ($Object | Get-Member -Name $Member)
}


<#
.SYNOPSIS
Возвращает $true, если используется модуль Azure версии 0.7.4 или более поздней. Иначе — $false.

.DESCRIPTION
Test-AzureModuleVersion возвращает $true, если используется модуль Azure версии 0.7.4 или более поздней. Если модуль не установлен или имеет более раннюю версию, возвращается значение $false. Эта функция не имеет параметров.

.INPUTS
Нет

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModuleVersion
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
0      7      4      -1

PS C:\> Test-AzureModuleVersion
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModuleVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Version]
        $Version
    )

    return ($Version.Major -gt 0) -or ($Version.Minor -gt 7) -or ($Version.Minor -eq 7 -and $Version.Build -ge 4)
}


<#
.SYNOPSIS
Возвращает $true, если установлен модуль Azure версии 0.7.4 или более поздней.

.DESCRIPTION
Test-AzureModule возвращает $true, если установлен модуль Azure версии 0.7.4 или более поздней. Если модуль не установлен или имеет более раннюю версию, возвращается значение $false. Эта функция не имеет параметров.

.INPUTS
Нет

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModule
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
    0      7      4      -1

PS C:\> Test-AzureModule
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModule
{
    [CmdletBinding()]

    $module = Get-Module -Name Azure

    if (!$module)
    {
        $module = Get-Module -Name Azure -ListAvailable

        if (!$module -or !(Test-AzureModuleVersion $module.Version))
        {
            return $false;
        }
        else
        {
            $ErrorActionPreference = 'Continue'
            Import-Module -Name Azure -Global -Verbose:$false
            $ErrorActionPreference = 'Stop'

            return $true
        }
    }
    else
    {
        return (Test-AzureModuleVersion $module.Version)
    }
}


<#
.SYNOPSIS
Сохраняет текущую подписку Windows Azure в переменной $Script:originalSubscription в области скрипта.

.DESCRIPTION
Функция Backup-Subscription сохраняет в области скрипта текущую подписку Windows Azure (Get-AzureSubscription -Current) и ее учетную запись хранения, а также подписку, изменяемую этим скриптом ($UserSpecifiedSubscription, и ее учетную запись хранения. Сохранение этих значений позволяет использовать функцию, такую как Restore-Subscription, для восстановления исходной текущей подписки и учетной записи хранения в текущем статусе в случае изменения текущего статуса.

.PARAMETER UserSpecifiedSubscription
Указывает имя подписки, в которой будут созданы и опубликованы новые ресурсы. Функция сохраняет имена подписки и ее учетных записей хранения в области скрипта. Это обязательный параметр.

.INPUTS
Нет

.OUTPUTS
Нет

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso
PS C:\>

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso -Verbose
VERBOSE: Backup-Subscription: Start
VERBOSE: Backup-Subscription: Original subscription is Windows Azure MSDN - Visual Studio Ultimate
VERBOSE: Backup-Subscription: End
#>
function Backup-Subscription
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $UserSpecifiedSubscription
    )

    Write-VerboseWithTime 'Backup-Subscription: начало'

    $Script:originalCurrentSubscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue
    if ($Script:originalCurrentSubscription)
    {
        Write-VerboseWithTime ('Backup-Subscription: исходная подписка: ' + $Script:originalCurrentSubscription.SubscriptionName)
        $Script:originalCurrentStorageAccount = $Script:originalCurrentSubscription.CurrentStorageAccountName
    }
    
    $Script:userSpecifiedSubscription = $UserSpecifiedSubscription
    if ($Script:userSpecifiedSubscription)
    {        
        $userSubscription = Get-AzureSubscription -SubscriptionName $Script:userSpecifiedSubscription -ErrorAction SilentlyContinue
        if ($userSubscription)
        {
            $Script:originalStorageAccountOfUserSpecifiedSubscription = $userSubscription.CurrentStorageAccountName
        }        
    }

    Write-VerboseWithTime 'Backup-Subscription: окончание'
}


<#
.SYNOPSIS
Восстанавливает "текущий" статус подписки Windows Azure, сохраненную в переменной $Script:originalSubscription в области скрипта.

.DESCRIPTION
Функция Restore-Subscription делает подписку, сохраненную в переменной $Script:originalSubscription, текущей подпиской (повторно). Если исходная подписка имела учетную запись хранения, эта учетная запись становится текущей для текущей подписки. Подписка восстанавливается только при наличии в среде переменной $SubscriptionName с отличным от null значением. В противном случае функция завершается. Если $SubscriptionName заполнено, но $Script:originalSubscription имеет значение $null, Restore-Subscription использует командлет Select-AzureSubscription для очистки параметров Current и Default для подписок в Windows Azure PowerShell. Эта функция не имеет параметров, не получает входных данных и ничего не возвращает (void). Можно использовать -Verbose для записи сообщений в поток Verbose.

.INPUTS
Нет

.OUTPUTS
Нет

.EXAMPLE
PS C:\> Restore-Subscription
PS C:\>

.EXAMPLE
PS C:\> Restore-Subscription -Verbose
VERBOSE: Restore-Subscription: Start
VERBOSE: Restore-Subscription: End
#>
function Restore-Subscription
{
    [CmdletBinding()]
    param()

    Write-VerboseWithTime 'Restore-Subscription: начало'

    if ($Script:originalCurrentSubscription)
    {
        if ($Script:originalCurrentStorageAccount)
        {
            Set-AzureSubscription `
                -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName `
                -CurrentStorageAccountName $Script:originalCurrentStorageAccount
        }

        Select-AzureSubscription -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName
    }
    else 
    {
        Select-AzureSubscription -NoCurrent
        Select-AzureSubscription -NoDefault
    }
    
    if ($Script:userSpecifiedSubscription -and $Script:originalStorageAccountOfUserSpecifiedSubscription)
    {
        Set-AzureSubscription `
            -SubscriptionName $Script:userSpecifiedSubscription `
            -CurrentStorageAccountName $Script:originalStorageAccountOfUserSpecifiedSubscription
    }

    Write-VerboseWithTime 'Restore-Subscription: окончание'
}

<#
.SYNOPSIS
Находит учетную запись хранения Windows Azure с именем "devtest*" в текущей подписке.

.DESCRIPTION
Функция Get-AzureVMStorage возвращает имя первой учетной записи хранения с шаблоном имени "devtest*" (без учета регистра) в указанном расположении или территориальной группе. Если учетная запись хранения "devtest*" не соответствует расположению или территориальной группе, функция ее игнорирует. Необходимо указать расположение или территориальную группу.

.PARAMETER  Location
Указывает расположение учетной записи хранения. Допустимыми значениями являются расположения Windows Azure, такие как "West US". Можно ввести расположение или территориальную группу, но не одновременно.

.PARAMETER  AffinityGroup
Указывает территориальную группу учетной записи хранения. Можно ввести расположение или территориальную группу, но не одновременно.

.INPUTS
Нет. В эту функцию невозможно передать входные данные.

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Get-AzureVMStorage -Location "East US"
devtest3-fabricam

.EXAMPLE
PS C:\> Get-AzureVMStorage -AffinityGroup Finance
PS C:\>

.EXAMPLE\
PS C:\> Get-AzureVMStorage -AffinityGroup Finance -Verbose
VERBOSE: Get-AzureVMStorage: Start
VERBOSE: Get-AzureVMStorage: End

.LINK
Get-AzureStorageAccount
#>
function Get-AzureVMStorage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Location')]
        [String]
        $Location,

        [Parameter(Mandatory = $true, ParameterSetName = 'AffinityGroup')]
        [String]
        $AffinityGroup
    )

    Write-VerboseWithTime 'Get-AzureVMStorage: начало'

    $storages = @(Get-AzureStorageAccount -ErrorAction SilentlyContinue)
    $storageName = $null

    foreach ($storage in $storages)
    {
        # Получение первой учетной записи хранения, имя которой начинается с "devtest".
        if ($storage.Label -like 'devtest*')
        {
            if ($storage.AffinityGroup -eq $AffinityGroup -or $storage.Location -eq $Location)
            {
                $storageName = $storage.Label

                    Write-HostWithTime ('Get-AzureVMStorage: найдена учетная запись хранения devtest ' + $storageName)
                    $storage | Out-String | Write-VerboseWithTime
                break
            }
        }
    }

    Write-VerboseWithTime 'Get-AzureVMStorage: окончание'
    return $storageName
}


<#
.SYNOPSIS
Создает новую учетной записи хранения Windows Azure с уникальным именем, начинающимся с "devtest".

.DESCRIPTION
Функция Add-AzureVMStorage создает новую учетную запись хранения Windows Azure в текущей подписке. Имя учетной записи начинается с "devtest", за которым следует уникальная строка букв и цифр. Функция возвращает имя новой учетной записи хранения. Необходимо указать расположение или территориальную группу для новой учетной записи хранения.

.PARAMETER  Location
Указывает расположение учетной записи хранения. Допустимыми значениями являются расположения Windows Azure, такие как "West US". Можно ввести расположение или территориальную группу, но не одновременно.

.PARAMETER  AffinityGroup
Указывает территориальную группу учетной записи хранения. Можно ввести расположение или территориальную группу, но не одновременно.

.INPUTS
Нет. В эту функцию невозможно передать входные данные.

.OUTPUTS
System.String. Строка представляет собой имя новой учетной записи хранения

.EXAMPLE
PS C:\> Add-AzureVMStorage -Location "East Asia"
devtestd6b45e23a6dd4bdab

.EXAMPLE
PS C:\> Add-AzureVMStorage -AffinityGroup Finance
devtestd6b45e23a6dd4bdab

.EXAMPLE
PS C:\> Add-AzureVMStorage -AffinityGroup Finance -Verbose
VERBOSE: Add-AzureVMStorage: Start
VERBOSE: Add-AzureVMStorage: Created new storage acccount devtestd6b45e23a6dd4bdab"
VERBOSE: Add-AzureVMStorage: End
devtestd6b45e23a6dd4bdab

.LINK
New-AzureStorageAccount
#>
function Add-AzureVMStorage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Location')]
        [String]
        $Location,

        [Parameter(Mandatory = $true, ParameterSetName = 'AffinityGroup')]
        [String]
        $AffinityGroup
    )

    Write-VerboseWithTime 'Add-AzureVMStorage: начало'

    # Создание уникального имени за счет добавления части GUID к "devtest"
    $name = 'devtest'
    $suffix = [guid]::NewGuid().ToString('N').Substring(0,24 - $name.Length)
    $name = $name + $suffix

    # Создание новой учетной записи хранения Windows Azure с расположением/территориальной группой
    if ($PSCmdlet.ParameterSetName -eq 'Location')
    {
        New-AzureStorageAccount -StorageAccountName $name -Location $Location | Out-Null
    }
    else
    {
        New-AzureStorageAccount -StorageAccountName $name -AffinityGroup $AffinityGroup | Out-Null
    }

    Write-HostWithTime ("Add-AzureVMStorage: создана новая учетная запись хранения $name")
    Write-VerboseWithTime 'Add-AzureVMStorage: окончание'
    return $name
}


<#
.SYNOPSIS
Проверяет файл конфигурации и возвращает хэш-таблицу значений файла конфигурации.

.DESCRIPTION
Функция Read-ConfigFile проверяет JSON-файл конфигурации и возвращает хэш-таблицу выбранных значений.
-- Сначала выполняется преобразование JSON-файла в PSCustomObject.
-- Проверяет, чтобы свойство environmentSettings содержало свойство либо веб-сайта, либо облачной службы, но не оба.
-- Создает и возвращает хэш-таблицу одного из двух типов: для веб-сайта или для облачной службы. Хэш-таблица веб-сайта имеет следующие ключи:
-- IsAzureWebSite: $True. Файл конфигурации для веб-сайта. 
-- Name: Имя веб-сайта
-- Location: Расположение веб-сайта
-- Databases: Базы данных SQL веб-сайта
Хэш-таблица облачной службы имеет следующие ключи:
-- IsAzureWebSite: $False. Файл конфигурации не для веб-сайта.
-- webdeployparameters : Необязательный атрибут. Может быть пустым или иметь значение $null.
-- Databases: Базы данных SQL

.PARAMETER  ConfigurationFile
Указывает путь и имя JSON-файла конфигурации для веб-проекта. Visual Studio автоматически создает JSON-файл конфигурации при создании веб-проекта и хранит его в папке PublishScripts вашего решения.

.PARAMETER HasWebDeployPackage
Indicates that there is a web deploy package ZIP file for the web application. To specify a value of $true, use -HasWebDeployPackage or HasWebDeployPackage:$true. To specify a value of false, use HasWebDeployPackage:$false.This parameter is required.

.INPUTS
Нет. В эту функцию невозможно передать входные данные.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Read-ConfigFile -ConfigurationFile <path> -HasWebDeployPackage


Name                           Value                                                                                                                                                                     
----                           -----                                                                                                                                                                     
databases                      {@{connectionStringName=; databaseName=; serverName=; user=; password=}}                                                                                                  
cloudService                   @{name=asdfhl; affinityGroup=stephwe1ag1cus; location=; virtualNetwork=; subnet=; availabilitySet=; virtualMachine=}                                                      
IsWAWS                         False                                                                                                                                                                     
webDeployParameters            @{iisWebApplicationName=Default Web Site} 
#>
function Read-ConfigFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $ConfigurationFile,

        [Parameter(Mandatory = $true)]
        [Switch]
        $HasWebDeployPackage	    
    )

    Write-VerboseWithTime 'Read-ConfigFile: начало'

    # Получение содержимого JSON-файла (-raw игнорирует разрывы строк) и его преобразование в PSCustomObject
    $config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json

    if (!$config)
    {
        throw ('Read-ConfigFile: сбой ConvertFrom-Json: ' + $error[0])
    }

    # Определение наличия у объекта environmentSettings свойств webSite или cloudService (без учета значения свойства)
    $hasWebsiteProperty =  Test-Member -Object $config.environmentSettings -Member 'webSite'
    $hasCloudServiceProperty = Test-Member -Object $config.environmentSettings -Member 'cloudService'

    if (!$hasWebsiteProperty -and !$hasCloudServiceProperty)
    {
        throw 'Read-ConfigFile: неправильный формат файла конфигурации. Отсутствует webSite или cloudService'
    }
    elseif ($hasWebsiteProperty -and $hasCloudServiceProperty)
    {
        throw 'Read-ConfigFile: неправильный формат файла конфигурации. Одновременно указаны webSite и cloudService'
    }

    # Построение хэш-таблицы из значений PSCustomObject
    $returnObject = New-Object -TypeName Hashtable
    $returnObject.Add('IsAzureWebSite', $hasWebsiteProperty)

    if ($hasWebsiteProperty)
    {
        $returnObject.Add('name', $config.environmentSettings.webSite.name)
        $returnObject.Add('location', $config.environmentSettings.webSite.location)
    }
    else
    {
        $returnObject.Add('cloudService', $config.environmentSettings.cloudService)
        if ($HasWebDeployPackage)
        {
            $returnObject.Add('webDeployParameters', $config.environmentSettings.webdeployParameters)
        }
    }

    if (Test-Member -Object $config.environmentSettings -Member 'databases')
    {
        $returnObject.Add('databases', $config.environmentSettings.databases)
    }

    Write-VerboseWithTime 'Read-ConfigFile: окончание'

    return $returnObject
}

<#
.SYNOPSIS
Добавляет новые входные конечные точки в виртуальную машину и возвращает виртуальную машину с новыми конечными точками.

.DESCRIPTION
Функция Add-AzureVMEndpoints добавляет новые входные конечные точки в виртуальную машину и возвращает виртуальную машину с новыми конечными точками. Эта функция вызывает командлет Add-AzureEndpoint (модуль Azure).

.PARAMETER  VM
Указывает объект виртуальной машины Введите объект виртуальной машины, такой как тип, возвращаемый командлетом New-AzureVM или Get-AzureVM. Можно передавать объекты из Get-AzureVM в Add-AzureVMEndpoints.

.PARAMETER  Endpoints
Указывает массив конечных точек для добавления в виртуальную машину. Источником этих конечных точек обычно является JSON-файл конфигурации, создаваемый Visual Studio для веб-проектов. Используйте функцию Read-ConfigFile в этом модуле для преобразования этого файла в хэш-таблицу. Конечные точки являются свойством ключа cloudservice в хэш-таблице ($<hashtable>.cloudservice.virtualmachine.endpoints). Пример
PS C:\> $config.cloudservice.virtualmachine.endpoints
name      protocol publicport privateport
----      -------- ---------- -----------
http      tcp      80         80
https     tcp      443        443
WebDeploy tcp      8172       8172

.INPUTS
Microsoft.WindowsAzure.Commands.ServiceManagement.Model.IPersistentVM

.OUTPUTS
Microsoft.WindowsAzure.Commands.ServiceManagement.Model.IPersistentVM

.EXAMPLE
Get-AzureVM

.EXAMPLE

.LINK
Get-AzureVM

.LINK
Add-AzureEndpoint
#>
function Add-AzureVMEndpoints
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVM]
        $VM,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $Endpoints
    )

    Write-VerboseWithTime 'Add-AzureVMEndpoints: начало'

    # Добавление каждой конечной точки из JSON-файла в виртуальную машину
    $Endpoints | ForEach-Object `
    {
        $_ | Out-String | Write-VerboseWithTime
        Add-AzureEndpoint -VM $VM -Name $_.name -Protocol $_.protocol -LocalPort $_.privateport -PublicPort $_.publicport | Out-Null
    }

    Write-VerboseWithTime 'Add-AzureVMEndpoints: окончание'
    return $VM
}

<#
.SYNOPSIS
Создает все элементы новой виртуальной машины в подписке Windows Azure.

.DESCRIPTION
Эта функция создает виртуальную машину Windows Azure и возвращает URL-адрес развернутой виртуальной машины. Функция настраивает обязательные требования, а затем вызывает командлет New-AzureVM (модуль Azure) для создания новой виртуальной машины. 
-- Вызывает командлет New-AzureVMConfig (модуль Azure) для получения объекта конфигурации виртуальной машины. 
-- Если включен параметр Subnet для добавления виртуальной машины в подсеть Azure, функция вызывает Set-AzureSubnet, чтобы установить список подсетей для виртуальной машины. 
-- Вызывает командлет Add-AzureProvisioningConfig (модуль Azure) для добавления элементов в конфигурацию виртуальной машины. Создает изолированную конфигурацию подготовки Windows (-Windows) с учетной записью и паролем администратора. 
-- Вызывает функцию Add-AzureVMEndpoints в этом модуле для добавления конечных точек, заданных параметром Endpoints. Эта функция получает объект виртуальной машин и возвращает объект виртуальной машины с добавленными конечными точками. 
-- Вызывает командлет Add-AzureVM для создания новой виртуальной машины Windows Azure и возвращает новую виртуальную машину. Значения параметров функции обычно берутся из JSON-файла конфигурации, который Visual Studio создает для интегрированных с Windows Azure веб-проектов. Функция Read-ConfigFile в этом модуле преобразует JSON-файл в хэш-таблицу. Сохраняет ключ cloudservice или хэш-таблицу в переменной (как PSCustomObject) и использует свойства пользовательского объекта как значения параметров.

.PARAMETER  UserName
Указывает имя пользователя администратора. Это значение передается в параметре AdminUserName командлета Add-AzureProvisioningConfig. Это обязательный параметр.

.PARAMETER  UserPassword
Указывает пароль для учетной записи администратора. Это значение передается в параметре Password командлета Add-AzureProvisioningConfig. Это обязательный параметр.

.PARAMETER  VMName
Указывает имя для новой виртуальной машины. Имя виртуальной машины должно быть уникальным в пределах облачной службы. Это обязательный параметр.

.PARAMETER  VMSize
Указывает размер виртуальной машины. Допустимые значения: "Очень мелкий", "Мелкий", "Средний", "Крупный" или "Очень крупный", "A5", "A6" и "A7". Это значение передается в параметре InstanceSize командлета New-AzureVMConfig. Это обязательный параметр. 

.PARAMETER  ServiceName
Указывает существующую службу Windows Azure или имя новой службы Windows Azure. Это имя передается в параметр ServiceName командлета New-AzureVM, который добавляет новую виртуальную машину в существующую службу Windows Azure или, если указано расположение или территориальная группа, создает новую виртуальную машину и службу в текущей подписке. Это обязательный параметр. 

.PARAMETER  ImageName
Указывает имя образа виртуальной машины для диска операционной системы. Этот параметр передается как значение параметра ImageName командлета New-AzureVMConfig cmdlet. Это обязательный параметр. 

.PARAMETER  Endpoints
Указывает массив конечных точек для добавления в виртуальную машину. Это значение передается в функцию Add-AzureVMEndpoints, которую этот модуль экспортирует. Это необязательный параметр. Источником этих конечных точек обычно является JSON-файл конфигурации, создаваемый Visual Studio для веб-проектов. Используйте функцию Read-ConfigFile в этом модуле для преобразования этого файла в хэш-таблицу. Конечные точки являются свойством ключа cloudService в хэш-таблице ($<hashtable>.cloudservice.virtualmachine.endpoints). 

.PARAMETER  AvailabilitySetName
Указывает имя группы доступности для новой виртуальной машины. Когда в одну группу доступности помещено несколько виртуальных машин, Windows Azure пытается держать эти виртуальные машины на отдельных узлах для обеспечения непрерывности обслуживания в случае сбоя одного из них. Это необязательный параметр. 

.PARAMETER  VNetName
Указывает имя виртуальной сети, в которой развертывается новая виртуальная машина. Это значение передается в параметр VNetName командлета Add-AzureVM. Это необязательный параметр. 

.PARAMETER  Location
Указывает расположение для новой виртуальной машины. Допустимыми значениями являются расположения Windows Azure, такие как "West US". По умолчанию — расположение подписки. Это необязательный параметр. 

.PARAMETER  AffinityGroup
Указывает территориальную группу для новой виртуальной машины. Территориальная группа — это группа связанных ресурсов. При указании территориальной группы Windows Azure пытается держать ресурсы этой группы вместе для повышения эффективности. 

.PARAMETER EnableWebDeployExtension
Подготавливает виртуальную машину для развертывания. Это необязательный параметр. Если он не указан, виртуальная машина создается, но не развертывается. Значение этого параметра включается в JSON-файл конфигурации, создаваемый Visual Studio для облачных служб.

.PARAMETER  Subnet
Указывает подсеть новой конфигурации виртуальной машины. Это значение передается в командлет Set-AzureSubnet (модуль Azure), который принимает виртуальную машину и массив имен подсетей и возвращает виртуальную машину с подсетями в конфигурации.

.INPUTS
Нет. Эта функция не получает входные данные из конвейера.

.OUTPUTS
System.Url

.EXAMPLE
 Эта команда вызывает функцию Add-AzureVM. Многие значения параметров берутся из объекта $CloudServiceConfiguration. Этот PSCustomObject представляет собой ключ cloudservice и значения хэш-таблицы, которые возвращает функция Read-ConfigFile. Источником является JSON-файл конфигурации, создаваемый Visual Studio для веб-проектов.

PS C:\> $config = Read-Configfile <name>.json
PS C:\> $CloudServiceConfiguration = config.cloudservice

PS C:\> Add-AzureVM `
-UserName $userName `
-UserPassword  $userPassword `
-ImageName $CloudServiceConfiguration.virtualmachine.vhdImage `
-VMName $CloudServiceConfiguration.virtualmachine.name `
-VMSize $CloudServiceConfiguration.virtualmachine.size`
-Endpoints $CloudServiceConfiguration.virtualmachine.endpoints `
-ServiceName $serviceName `
-Location $CloudServiceConfiguration.location `
-AvailabilitySetName $CloudServiceConfiguration.availabilitySet `
-VNetName $CloudServiceConfiguration.virtualNetwork `
-Subnet $CloudServiceConfiguration.subnet `
-AffinityGroup $CloudServiceConfiguration.affinityGroup `
-EnableWebDeployExtension

http://contoso.cloudapp.net

.EXAMPLE
PS C:\> $endpoints = [PSCustomObject]@{name="http";protocol="tcp";publicport=80;privateport=80}, `
                        [PSCustomObject]@{name="https";protocol="tcp";publicport=443;privateport=443},`
                        [PSCustomObject]@{name="WebDeploy";protocol="tcp";publicport=8172;privateport=8172}
PS C:\> Add-AzureVM `
-UserName admin01 `
-UserPassword "pa$$word" `
-ImageName bd507d3a70934695bc2128e3e5a255ba__RightImage-Windows-2012-x64-v13.4.12.2 `
-VMName DevTestVM123 `
-VMSize Small `
-Endpoints $endpoints `
-ServiceName DevTestVM1234 `
-Location "West US"

.LINK
New-AzureVMConfig

.LINK
Set-AzureSubnet

.LINK
Add-AzureProvisioningConfig

.LINK
Get-AzureDeployment
#>
function Add-AzureVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserPassword,

        [Parameter(Mandatory = $true)]
        [String]
        $VMName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMSize,

        [Parameter(Mandatory = $true)]
        [String]
        $ServiceName,

        [Parameter(Mandatory = $true)]
        [String]
        $ImageName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Object[]]
        $Endpoints,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $AvailabilitySetName,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $VNetName,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $Location,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $AffinityGroup,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $Subnet,

        [Parameter(Mandatory = $false)]
        [Switch]
        $EnableWebDeployExtension
    )

    Write-VerboseWithTime 'Add-AzureVM: начало'

    # Создание нового объекта конфигурации Windows Azure.
    if ($AvailabilitySetName)
    {
        $vm = New-AzureVMConfig -Name $VMName -InstanceSize $VMSize -ImageName $ImageName -AvailabilitySetName $AvailabilitySetName
    }
    else
    {
        $vm = New-AzureVMConfig -Name $VMName -InstanceSize $VMSize -ImageName $ImageName
    }

    if (!$vm)
    {
        throw 'Add-AzureVM: не удалось создать конфигурацию виртуальной машины Azure.'
    }

    if ($Subnet)
    {
        # Установка списка подсетей для конфигурации виртуальной машины.
        $subnetResult = Set-AzureSubnet -VM $vm -SubnetNames $Subnet

        if (!$subnetResult)
        {
            throw ('Add-AzureVM: не удалось установить подсеть ' + $Subnet)
        }
    }

    # Добавление данных конфигурации в конфигурацию виртуальной машины
    $VMWithConfig = Add-AzureProvisioningConfig -VM $vm -Windows -Password $UserPassword -AdminUserName $UserName

    if (!$VMWithConfig)
    {
        throw ('Add-AzureVM: не удалось создать конфигурацию подготовки.')
    }

    # Добавление конечных точек ввода в виртуальную машину
    if ($Endpoints -and $Endpoints.Count -gt 0)
    {
        $VMWithConfig = Add-AzureVMEndpoints -Endpoints $Endpoints -VM $VMWithConfig
    }

    if (!$VMWithConfig)
    {
        throw ('Add-AzureVM: не удалось создать конечные точки.')
    }

    if ($EnableWebDeployExtension)
    {
        Write-VerboseWithTime 'Add-AzureVM: добавить расширение webdeploy'

        Write-VerboseWithTime 'Условия лицензии WebDeploy см. по адресу http://go.microsoft.com/fwlink/?LinkID=389744 '

        $VMWithConfig = Set-AzureVMExtension `
            -VM $VMWithConfig `
            -ExtensionName WebDeployForVSDevTest `
            -Publisher 'Microsoft.VisualStudio.WindowsAzure.DevTest' `
            -Version '1.*' 

        if (!$VMWithConfig)
        {
            throw ('Add-AzureVM: не удалось добавить расширение webdeploy.')
        }
    }

    # Создание кэш-таблицы параметров для сплаттинга
    $param = New-Object -TypeName Hashtable
    if ($VNetName)
    {
        $param.Add('VNetName', $VNetName)
    }

    if ($Location)
    {
        $param.Add('Location', $Location)
    }

    if ($AffinityGroup)
    {
        $param.Add('AffinityGroup', $AffinityGroup)
    }

    $param.Add('ServiceName', $ServiceName)
    $param.Add('VMs', $VMWithConfig)
    $param.Add('WaitForBoot', $true)

    $param | Out-String | Write-VerboseWithTime

    New-AzureVM @param | Out-Null

    Write-HostWithTime ('Add-AzureVM: создана виртуальная машина ' + $VMName)

    $url = [System.Uri](Get-AzureDeployment -ServiceName $ServiceName).Url

    if (!$url)
    {
        throw 'Add-AzureVM: не удается найти URL-адрес виртуальной машины.'
    }

    Write-HostWithTime ('Add-AzureVM: URL-адрес публикации https://' + $url.Host + ':' + $WebDeployPort + '/msdeploy.axd')

    Write-VerboseWithTime 'Add-AzureVM: окончание'

    return $url.AbsoluteUri
}


<#
.SYNOPSIS
Получает указанную виртуальную машину Windows Azure.

.DESCRIPTION
Функция Find-AzureVM получает виртуальную машину Windows Azure по имени службы и имени виртуальной машины. Эта функция вызывает командлет Test-AzureName (модуль Azure), чтобы проверить существование имени службы в Windows Azure. Если имя существует, функция вызывает командлет Get-AzureVM для получения виртуальной машины. Функция возвращает хэш-таблицу с ключами vm и foundService.
-- FoundService: $True, если Test-AzureName находит функцию. В противном случае — $False
-- VM: Содержит объект виртуальной машины, когда FoundService имеет значение true, а Get-AzureVM возвращает объект виртуальной машины.

.PARAMETER  ServiceName
Имя существующей службы Windows Azure. Это обязательный параметр.

.PARAMETER  VMName
Имя виртуальной машины в службе. Это обязательный параметр.

.INPUTS
Нет. В эту функцию невозможно передать входные данные.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Find-AzureVM -Service Contoso -Name ContosoVM2

Name                           Value
----                           -----
foundService                   True

DeploymentName        : Contoso
Name                  : ContosoVM2
Label                 :
VM                    : Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVM
InstanceStatus        : ReadyRole
IpAddress             : 100.71.114.118
InstanceStateDetails  :
PowerState            : Started
InstanceErrorCode     :
InstanceFaultDomain   : 0
InstanceName          : ContosoVM2
InstanceUpgradeDomain : 0
InstanceSize          : Small
AvailabilitySetName   :
DNSName               : http://contoso.cloudapp.net/
ServiceName           : Contoso
OperationDescription  : Get-AzureVM
OperationId           : 3c38e933-9464-6876-aaaa-734990a882d6
OperationStatus       : Succeeded

.LINK
Get-AzureVM
#>
function Find-AzureVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMName
    )

    Write-VerboseWithTime 'Find-AzureVM: начало'
    $foundService = $false
    $vm = $null

    if (Test-AzureName -Service -Name $ServiceName)
    {
        $foundService = $true
        $vm = Get-AzureVM -ServiceName $ServiceName -Name $VMName
        if ($vm)
        {
            Write-HostWithTime ('Find-AzureVM: найдена существующая виртуальная машина ' + $vm.Name )
            $vm | Out-String | Write-VerboseWithTime
        }
    }

    Write-VerboseWithTime 'Find-AzureVM: окончание'
    return @{ VM = $vm; FoundService = $foundService }
}


<#
.SYNOPSIS
Находит или создает в подписке виртуальную машину, соответствующую значениям в JSON-файле конфигурации.

.DESCRIPTION
Функция New-AzureVMEnvironment находит или создает виртуальную машину в подписке, соответствующей значениям в JSON-файле конфигурации, создаваемом Visual Studio для веб-проектов. Используется PSCustomObject, являющийся ключом cloudservice хэш-таблицы, которую возвращает Read-ConfigFile. Источником этих данных является JSON-файл конфигурации, создаваемый Visual Studio. Функция выполняет в подписке поиск виртуальной машины с именем службы и именем виртуальной машины, которые соответствуют значениям в пользовательском объекте CloudServiceConfiguration. Если найти соответствующую виртуальную машину не удается, вызывается функция Add-AzureVM в этом модуле, которая использует значения в объекте CloudServiceConfiguration для создания виртуальной машины. Среда виртуальной машины включает учетную запись хранения, имя которой начинается с "devtest". Если функции не удается найти в подписке учетную запись хранения таким шаблоном имени, она создает новую. Функция возвращает хэш-таблицу с ключами и строковыми значениями VmUrl, userName и Password.

.PARAMETER  CloudServiceConfiguration
Принимает PSCustomObject, содержащий свойство cloudservice хэш-таблицы, которую возвращает функция Read-ConfigFile. Источником всех значений является JSON-файл конфигурации, создаваемый Visual Studio для веб-проектов. Этот файл можно найти в папке PublishScripts решения. Это обязательный параметр.
$config = Read-ConfigFile -ConfigurationFile <file>.json $cloudServiceConfiguration = $config.cloudService

.PARAMETER  VMPassword
Принимает хэш-таблицу с ключами name и password, например: @{Name = "admin"; Password = "pa$$word"} Это необязательный параметр. Если он опущен, по умолчанию используются значения имени пользователя виртуальной машины и пароля в JSON-файле конфигурации.

.INPUTS
PSCustomObject  System.Collections.Hashtable

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
$config = Read-ConfigFile -ConfigurationFile $<file>.json
$cloudSvcConfig = $config.cloudService
$namehash = @{name = "admin"; password = "pa$$word"}

New-AzureVMEnvironment `
    -CloudServiceConfiguration $cloudSvcConfig `
    -VMPassword $namehash

Name                           Value
----                           -----
UserName                       admin
VMUrl                          contoso.cloudnet.net
Password                       pa$$word

.LINK
Add-AzureVM

.LINK
New-AzureStorageAccount
#>
function New-AzureVMEnvironment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $CloudServiceConfiguration,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMPassword
    )

    Write-VerboseWithTime ('New-AzureVMEnvironment: начало')

    if ($CloudServiceConfiguration.location -and $CloudServiceConfiguration.affinityGroup)
    {
        throw 'New-AzureVMEnvironment: неправильный формат файла конфигурации. Одновременно указаны location и affinityGroup'
    }

    if (!$CloudServiceConfiguration.location -and !$CloudServiceConfiguration.affinityGroup)
    {
        throw 'New-AzureVMEnvironment: неправильный формат файла конфигурации. Отсутствует location или affinityGroup'
    }

    # Если у объекта CloudServiceConfiguration есть свойство name (для имени службы) и для свойства name задано значение, используйте его. В противном случае используйте имя виртуальной машины в объекте CloudServiceConfiguration, которое заполняется всегда.
    if ((Test-Member $CloudServiceConfiguration 'name') -and $CloudServiceConfiguration.name)
    {
        $serviceName = $CloudServiceConfiguration.name
    }
    else
    {
        $serviceName = $CloudServiceConfiguration.virtualMachine.name
    }

    if (!$VMPassword)
    {
        $userName = $CloudServiceConfiguration.virtualMachine.user
        $userPassword = $CloudServiceConfiguration.virtualMachine.password
    }
    else
    {
        $userName = $VMPassword.Name
        $userPassword = $VMPassword.Password
    }

    # Получение имени виртуальной машины из JSON-файла
    $findAzureVMResult = Find-AzureVM -ServiceName $serviceName -VMName $CloudServiceConfiguration.virtualMachine.name

    # Если в указанной облачной службе не удастся найти виртуальную машину с указанным именем, создайте ее.
    if (!$findAzureVMResult.VM)
    {
        $storageAccountName = $null
        $imageInfo = Get-AzureVMImage -ImageName $CloudServiceConfiguration.virtualmachine.vhdimage 
        if ($imageInfo -and $imageInfo.Category -eq 'User')
        {
            $storageAccountName = ($imageInfo.MediaLink.Host -split '\.')[0]
        }

        if (!$storageAccountName)
        {
            if ($CloudServiceConfiguration.location)
            {
                $storageAccountName = Get-AzureVMStorage -Location $CloudServiceConfiguration.location
            }
            else
            {
                $storageAccountName = Get-AzureVMStorage -AffinityGroup $CloudServiceConfiguration.affinityGroup
            }
        }

        #If there's no devtest* storage account, create one.
        if (!$storageAccountName)
        {
            if ($CloudServiceConfiguration.location)
            {
                $storageAccountName = Add-AzureVMStorage -Location $CloudServiceConfiguration.location
            }
            else
            {
                $storageAccountName = Add-AzureVMStorage -AffinityGroup $CloudServiceConfiguration.affinityGroup
            }
        }

        $currentSubscription = Get-AzureSubscription -Current

        if (!$currentSubscription)
        {
            throw 'New-AzureVMEnvironment: не удалось получить текущую подписку Azure.'
        }

        # Установка учетной записи хранения devtest* как текущей
        Set-AzureSubscription `
            -SubscriptionName $currentSubscription.SubscriptionName `
            -CurrentStorageAccountName $storageAccountName

        Write-VerboseWithTime ('New-AzureVMEnvironment: установлена учетная запись хранения ' + $storageAccountName)

        $location = ''            
        if (!$findAzureVMResult.FoundService)
        {
            $location = $CloudServiceConfiguration.location
        }

        $endpoints = $null
        if (Test-Member -Object $CloudServiceConfiguration.virtualmachine -Member 'Endpoints')
        {
            $endpoints = $CloudServiceConfiguration.virtualmachine.endpoints
        }

        # Создание виртуальной машины со значениями из JSON-файла + значения параметров
        $VMUrl = Add-AzureVM `
            -UserName $userName `
            -UserPassword $userPassword `
            -ImageName $CloudServiceConfiguration.virtualMachine.vhdImage `
            -VMName $CloudServiceConfiguration.virtualMachine.name `
            -VMSize $CloudServiceConfiguration.virtualMachine.size`
            -Endpoints $endpoints `
            -ServiceName $serviceName `
            -Location $location `
            -AvailabilitySetName $CloudServiceConfiguration.availabilitySet `
            -VNetName $CloudServiceConfiguration.virtualNetwork `
            -Subnet $CloudServiceConfiguration.subnet `
            -AffinityGroup $CloudServiceConfiguration.affinityGroup `
            -EnableWebDeployExtension:$CloudServiceConfiguration.virtualMachine.enableWebDeployExtension

        Write-VerboseWithTime ('New-AzureVMEnvironment: окончание')

        return @{ 
            VMUrl = $VMUrl; 
            UserName = $userName; 
            Password = $userPassword; 
            IsNewCreatedVM = $true; }
    }
    else
    {
        Write-VerboseWithTime ('New-AzureVMEnvironment: найдена существующая виртуальная машина ' + $findAzureVMResult.VM.Name)
    }

    Write-VerboseWithTime ('New-AzureVMEnvironment: окончание')

    return @{ 
        VMUrl = $findAzureVMResult.VM.DNSName; 
        UserName = $userName; 
        Password = $userPassword; 
        IsNewCreatedVM = $false; }
}


<#
.SYNOPSIS
Возвращает команду для выполнения средства MsDeploy.exe

.DESCRIPTION
Функция Get-MSDeployCmd составляет и возвращает действительную команду для выполнения средства веб-развертывания, MSDeploy.exe. Правильный путь к средству функция находит в реестре локального компьютера. Эта функция не имеет параметров.

.INPUTS
Нет

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Get-MSDeployCmd
C:\Program Files\IIS\Microsoft Web Deploy V3\MsDeploy.exe

.LINK
Get-MSDeployCmd

.LINK
Web Deploy Tool
http://technet.microsoft.com/en-us/library/dd568996(v=ws.10).aspx
#>
function Get-MSDeployCmd
{
    Write-VerboseWithTime 'Get-MSDeployCmd: начало'
    $regKey = 'HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy'

    if (!(Test-Path $regKey))
    {
        throw ('Get-MSDeployCmd: не удается найти ' + $regKey)
    }

    $versions = @(Get-ChildItem $regKey -ErrorAction SilentlyContinue)
    $lastestVersion =  $versions | Sort-Object -Property Name -Descending | Select-Object -First 1

    if ($lastestVersion)
    {
        $installPathKeys = 'InstallPath','InstallPath_x86'

        foreach ($installPathKey in $installPathKeys)
        {		    	
            $installPath = $lastestVersion.GetValue($installPathKey)

            if ($installPath)
            {
                $installPath = Join-Path $installPath -ChildPath 'MsDeploy.exe'

                if (Test-Path $installPath -PathType Leaf)
                {
                    $msdeployPath = $installPath
                    break
                }
            }
        }
    }

    Write-VerboseWithTime 'Get-MSDeployCmd: окончание'
    return $msdeployPath
}


<#
.SYNOPSIS
Создает веб-сайт Windows Azure.

.DESCRIPTION
Создает веб-сайт Windows Azure с определенным именем и расположением. Эта функция вызывает командлет New-AzureWebsite в модуле Azure. Если подписка еще не имеет веб-сайта с указанным именем, эта функция создает такой веб-сайт и возвращает объект веб-сайта. В противном случае функция возвращает $null.

.PARAMETER  Name
Указывает имя для нового веб-сайта. Имя виртуальной машины должно быть уникальным в Windows Azure. Это обязательный параметр.

.PARAMETER  Location
Указывает расположение веб-сайта. Допустимыми значениями являются расположения Windows Azure, такие как "West US". Это обязательный параметр.

.INPUTS
НЕТ.

.OUTPUTS
Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.Site

.EXAMPLE
Add-AzureWebsite -Name TestSite -Location "West US"

Name       : contoso
State      : Running
Host Names : contoso.azurewebsites.net

.LINK
New-AzureWebsite
#>
function Add-AzureWebsite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Location
    )

    Write-VerboseWithTime 'Add-AzureWebsite: начало'
    $website = Get-AzureWebsite -Name $Name -ErrorAction SilentlyContinue

    if ($website)
    {
        Write-HostWithTime ('Add-AzureWebsite: существующий веб-сайт ' +
        $website.Name + ' найден')
    }
    else
    {
        if (Test-AzureName -Website -Name $Name)
        {
            Write-ErrorWithTime ('Веб-сайт {0} уже существует' -f $Name)
        }
        else
        {
            $website = New-AzureWebsite -Name $Name -Location $Location
        }
    }

    $website | Out-String | Write-VerboseWithTime
    Write-VerboseWithTime 'Add-AzureWebsite: окончание'

    return $website
}

<#
.SYNOPSIS
Возвращает значение $True, если URL-адрес является абсолютным и использует схему https.

.DESCRIPTION
Функция Test-HttpsUrl преобразует входной URL-адрес в объект System.Uri. Возвращает значение $True, если URL-адрес является абсолютным (не относительным) и использует схему https. Если любое из этих условий не выполняется или входную строку невозможно преобразовать в URL-адрес, функция возвращает $false.

.PARAMETER Url
Указывает URL-адрес для тестирования. Введите строку URL-адреса

.INPUTS
НЕТ.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\>$profile.publishUrl
waws-prod-bay-001.publish.azurewebsites.windows.net:443

PS C:\>Test-HttpsUrl -Url 'waws-prod-bay-001.publish.azurewebsites.windows.net:443'
False
#>
function Test-HttpsUrl
{

    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Url
    )

    # Если $uri невозможно преобразовать в объект System.Uri, Test-HttpsUrl возвращает $false
    $uri = $Url -as [System.Uri]

    return $uri.IsAbsoluteUri -and $uri.Scheme -eq 'https'
}


<#
.SYNOPSIS
Развертывает веб-пакет в Windows Azure.

.DESCRIPTION
Функция Publish-WebPackage использует MsDeploy.exe и ZIP-файл пакета веб-развертывания для развертывания ресурсов в веб-сайт Windows Azure. Эта функция не создает выходных данных. В случае сбоя вызова MSDeploy.exe функция создает исключение. Для получения более подробного вывода используйте общий параметр Verbose.

.PARAMETER  WebDeployPackage
Указывает путь и имя ZIP-файла пакета веб-развертывания, созданного Visual Studio. Это обязательный параметр. Сведения о создании ZIP-файла пакета веб-развертывания см. в разделе "Практическое руководство. Создание пакета веб-развертывания в Visual Studio" по адресу: http://go.microsoft.com/fwlink/?LinkId=391353.

.PARAMETER PublishUrl
Указывает URL-адрес, по которому развертываются ресурсы. URL-адрес должен использовать протокол HTTPS и включать порт. Это обязательный параметр.

.PARAMETER SiteName
Указывает имя для веб-сайта. Это обязательный параметр.

.PARAMETER Username
Указывает имя пользователя администратора веб-сайта. Это обязательный параметр.

.PARAMETER Password
Указывает пароль для администратора веб-сайта. Введите пароль в виде обычного текста. Защищенные строки запрещены. Это обязательный параметр.

.PARAMETER AllowUntrusted
Разрешает недоверенные SSL-соединения с сайтом. Этот параметр используется в вызове MSDeploy.exe. Это обязательный параметр.

.PARAMETER ConnectionString
Указывает строку подключения для базы данных SQL. Этот параметр принимает хэш-таблицу с ключами Name и ConnectionString. Значение Name представляет имя базы данных. Значение ConnectionString — connectionStringName в JSON-файле конфигурации.

.INPUTS
Нет. Эта функция не получает входные данные из конвейера.

.OUTPUTS
Нет

.EXAMPLE
Publish-WebPackage -WebDeployPackage C:\Documents\Azure\ADWebApp.zip `
    -PublishUrl $publishUrl "https://contoso.cloudnet.net:8172/msdeploy.axd" `
    -SiteName 'Тестовый сайт Contoso' `
    -UserName $UserName admin01 `
    -Password $UserPassword pa$$word `
    -AllowUntrusted:$False `
    -ConnectionString @{Name='TestDB';ConnectionString='DefaultConnection'}

.LINK
Publish-WebPackageToVM

.LINK
Web Deploy Command Line Reference (MSDeploy.exe)
http://go.microsoft.com/fwlink/?LinkId=391354
#>
function Publish-WebPackage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-HttpsUrl $_ })]
        [String]
        $PublishUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password,

        [Parameter(Mandatory = $false)]
        [Switch]
        $AllowUntrusted = $false,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ConnectionString
    )

    Write-VerboseWithTime 'Publish-WebPackage: начало'

    $msdeployCmd = Get-MSDeployCmd

    if (!$msdeployCmd)
    {
        throw 'Publish-WebPackage: не удается найти MsDeploy.exe.'
    }

    $WebDeployPackage = (Get-Item $WebDeployPackage).FullName

    $msdeployCmd =  '"' + $msdeployCmd + '"'
    $msdeployCmd += ' -verb:sync'
    $msdeployCmd += ' -Source:Package="{0}"'
    $msdeployCmd += ' -dest:auto,computername="{1}?site={2}",userName={3},password={4},authType=Basic'
    if ($AllowUntrusted)
    {
        $msdeployCmd += ' -allowUntrusted'
    }
    $msdeployCmd += ' -setParam:name="IIS Web Application Name",value="{2}"'

    foreach ($DBConnection in $ConnectionString.GetEnumerator())
    {
        $msdeployCmd += (' -setParam:name="{0}",value="{1}"' -f $DBConnection.Key, $DBConnection.Value)
    }

    $msdeployCmd = $msdeployCmd -f $WebDeployPackage, $PublishUrl, $SiteName, $UserName, $Password

    Write-VerboseWithTime ('Publish-WebPackage: MsDeploy: ' + $msdeployCmd)

    $msdeployExecution = Start-Process cmd.exe -ArgumentList ('/C "' + $msdeployCmd + '" ') -WindowStyle Normal -Wait -PassThru

    if ($msdeployExecution.ExitCode -ne 0)
    {
         Write-VerboseWithTime ('Выполнение Msdeploy.exe завершено с ошибкой. ExitCode:' + $msdeployExecution.ExitCode)
    }

    Write-VerboseWithTime 'Publish-WebPackage: окончание'
    return ($msdeployExecution.ExitCode -eq 0)
}


<#
.SYNOPSIS
Развертывает виртуальную машину в Windows Azure.

.DESCRIPTION
Вспомогательная функция Publish-WebPackageToVM проверяет значения параметров, а затем вызывает функцию Publish-WebPackage.

.PARAMETER  VMDnsName
Указывает DNS-имя виртуальной машины Windows Azure. Это обязательный параметр.

.PARAMETER IisWebApplicationName
Указывает веб-приложения IIS для виртуальной машины. Это обязательный параметр. Это имя вашего веб-приложения Visual Studio. Это имя можно найти в атрибуте webDeployparameters JSON-файла конфигурации, создаваемого Visual Studio.

.PARAMETER WebDeployPackage
Указывает путь и имя ZIP-файла пакета веб-развертывания, созданного Visual Studio. Это обязательный параметр. Сведения о создании ZIP-файла пакета веб-развертывания см. в разделе "Практическое руководство. Создание пакета веб-развертывания в Visual Studio" по адресу: http://go.microsoft.com/fwlink/?LinkId=391353.

.PARAMETER Username
Указывает имя пользователя администратора виртуальной машины. Это обязательный параметр.

.PARAMETER Password
Указывает пароль для администратора виртуальной машины. Введите пароль в виде обычного текста. Защищенные строки запрещены. Это обязательный параметр.

.PARAMETER AllowUntrusted
Разрешает недоверенные SSL-соединения с сайтом. Этот параметр используется в вызове MSDeploy.exe. Это обязательный параметр.

.PARAMETER ConnectionString
Указывает строку подключения для базы данных SQL. Этот параметр принимает хэш-таблицу с ключами Name и ConnectionString. Значение Name представляет имя базы данных. Значение ConnectionString — connectionStringName в JSON-файле конфигурации.

.INPUTS
Нет. Эта функция не получает входные данные из конвейера.

.OUTPUTS
Нет.

.EXAMPLE
Publish-WebPackageToVM -VMDnsName contoso.cloudapp.net `
-IisWebApplicationName myTestWebApp `
-WebDeployPackage C:\Documents\Azure\ADWebApp.zip
-Username admin01 `
-Password pa$$word `
-AllowUntrusted:$False `
-ConnectionString @{Name='TestDB';ConnectionString='DefaultConnection'}

.LINK
Publish-WebPackage
#>
function Publish-WebPackageToVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMDnsName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $IisWebApplicationName,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $UserPassword,

        [Parameter(Mandatory = $true)]
        [Bool]
        $AllowUntrusted,
        
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ConnectionString
    )
    Write-VerboseWithTime 'Publish-WebPackageToVM: начало'

    $VMDnsUrl = $VMDnsName -as [System.Uri]

    if (!$VMDnsUrl)
    {
        throw ('Publish-WebPackageToVM: недействительный URL-адрес ' + $VMDnsUrl)
    }

    $publishUrl = 'https://{0}:{1}/msdeploy.axd' -f $VMDnsUrl.Host, $WebDeployPort

    $result = Publish-WebPackage `
        -WebDeployPackage $WebDeployPackage `
        -PublishUrl $publishUrl `
        -SiteName $IisWebApplicationName `
        -UserName $UserName `
        -Password $UserPassword `
        -AllowUntrusted:$AllowUntrusted `
        -ConnectionString $ConnectionString

    Write-VerboseWithTime 'Publish-WebPackageToVM: окончание'
    return $result
}


<#
.SYNOPSIS
Создает строку, которая позволяет подключиться к базе данных SQL Windows Azure.

.DESCRIPTION
Функция Get-AzureSQLDatabaseConnectionString выполняет сборку строки подключения для подключения к базе данных SQL Windows Azure.

.PARAMETER  DatabaseServerName
Указывает имя существующего сервера баз данных в подписке Windows Azure. Все базы данных SQL Windows Azure должны быть связаны с сервером баз данных SQL. Для получения имени сервера используйте командлет Get-AzureSqlDatabaseServer (модуль Azure). Это обязательный параметр.

.PARAMETER  DatabaseName
Указывает имя для базы данных SQL. Это может быть существующая база данных SQL или имя, используемое для новой базы данных SQL. Это обязательный параметр.

.PARAMETER  Username
Указывает имя пользователя администратора базы данных SQL. Имя пользователя имеет вид $Username@DatabaseServerName. Это обязательный параметр.

.PARAMETER  Password
Указывает пароль для администратора базы данных SQL. Введите пароль в виде обычного текста. Защищенные строки запрещены. Это обязательный параметр.

.INPUTS
Нет.

.OUTPUTS
System.String

.EXAMPLE
PS C:\> $ServerName = (Get-AzureSqlDatabaseServer).ServerName
PS C:\> Get-AzureSQLDatabaseConnectionString -DatabaseServerName $ServerName `
        -DatabaseName 'testdb' -UserName 'admin'  -Password 'pa$$word'

Server=tcp:bebad12345.database.windows.net,1433;Database=testdb;User ID=admin@bebad12345;Password=pa$$word;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
#>
function Get-AzureSQLDatabaseConnectionString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password
    )

    return ('Server=tcp:{0}.database.windows.net,1433;Database={1};' +
           'User ID={2}@{0};' +
           'Password={3};' +
           'Trusted_Connection=False;' +
           'Encrypt=True;' +
           'Connection Timeout=20;') `
           -f $DatabaseServerName, $DatabaseName, $UserName, $Password
}


<#
.SYNOPSIS
Создает базы данных SQL Windows Azure из значений в создаваемом Visual Studio JSON-файле конфигурации.

.DESCRIPTION
Функция Add-AzureSQLDatabases получает информацию из раздела databases JSON-файла. Эта функция, Add-AzureSQLDatabases (мн. ч.), вызывает функцию Add-AzureSQLDatabase (ед. ч.) для каждой базы данных в JSON-файле. Add-AzureSQLDatabase (ед. ч.) вызывает командлет New-AzureSqlDatabase (модуль Azure), который создает базы данных. Эта функция не возвращает объект базы данных. Она возвращает хэш-таблицу значений, использовавшихся для создания баз данных.

.PARAMETER DatabaseConfig
 Принимает массив объектов PSCustomObjects, источником которых является JSON-файл, возвращаемый функцией Read-ConfigFile при наличии у JSON-файла свойства веб-сайта. Включает свойства environmentSettings.databases. Список можно передать в эту функцию.
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where connectionStringName
PS C:\> $DatabaseConfig
connectionStringName: Default Connection
databasename : TestDB1
edition   :
size     : 1
collation  : SQL_Latin1_General_CP1_CI_AS
servertype  : New SQL Database Server
servername  : r040tvt2gx
user     : dbuser
password   : Test.123
location   : West US

.PARAMETER  DatabaseServerPassword
Указывает пароль для администратора сервера баз данных SQL. Введите хэш-таблицу с ключами Name и Password. Значение name является именем сервера баз данных. Значение password является паролем администратора. Например: @Name = "TestDB1"; Password = "pa$$word" Это необязательный параметр. Если он не указан или имя сервера баз данных не совпадает со значением свойства serverName объекта $DatabaseConfig, функция использует свойство Password объекта $DatabaseConfig для базы данных SQL в строке подключения.

.PARAMETER CreateDatabase
Проверяет необходимость создания базы данных. Это необязательный параметр.

.INPUTS
System.Collections.Hashtable[]

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where $connectionStringName
PS C:\> $DatabaseConfig | Add-AzureSQLDatabases

Name                           Value
----                           -----
ConnectionString               Server=tcp:testdb1.database.windows.net,1433;Database=testdb;User ID=admin@testdb1;Password=pa$$word;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
Name                           Default Connection
Type                           SQLAzure

.LINK
Get-AzureSQLDatabaseConnectionString

.LINK
Create-AzureSQLDatabase
#>
function Add-AzureSQLDatabases
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $DatabaseConfig,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword,

        [Parameter(Mandatory = $false)]
        [Switch]
        $CreateDatabase = $true
    )

    begin
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: начало'
    }
    process
    {
        Write-VerboseWithTime ('Add-AzureSQLDatabases: создание ' + $DatabaseConfig.databaseName)

        if ($CreateDatabase)
        {
            # Создает новую базу данных SQL со значениями DatabaseConfig (если такой БД еще не существует)
            # Выходной поток команды подавлен.
            Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig | Out-Null
        }

        $serverPassword = $null
        if ($DatabaseServerPassword)
        {
            foreach ($credential in $DatabaseServerPassword)
            {
               if ($credential.Name -eq $DatabaseConfig.serverName)
               {
                   $serverPassword = $credential.password             
                   break
               }
            }               
        }

        if (!$serverPassword)
        {
            $serverPassword = $DatabaseConfig.password
        }

        return @{
            Name = $DatabaseConfig.connectionStringName;
            Type = 'SQLAzure';
            ConnectionString = Get-AzureSQLDatabaseConnectionString `
                -DatabaseServerName $DatabaseConfig.serverName `
                -DatabaseName $DatabaseConfig.databaseName `
                -UserName $DatabaseConfig.user `
                -Password $serverPassword }
    }
    end
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: окончание'
    }
}


<#
.SYNOPSIS
Создает новую базу данных SQL Windows Azure.

.DESCRIPTION
Функция Add-AzureSQLDatabase создает базу данных SQL Windows Azure из данных в JSON-файле конфигурации, создаваемом Visual Studio, и возвращает эту новую базу данных. Если у подписки уже есть база данных SQL с указанным именем базы данных на указанном сервере баз данных SQL, функция возвращает существующую базу данных. Эта функция вызывает командлет New-AzureSqlDatabase (модуль Azure), который фактически создает базу данных SQL.

.PARAMETER DatabaseConfig
Принимает объект PSCustomObject, источником которого является JSON-файл конфигурации, возвращаемый функцией Read-ConfigFile при наличии у JSON-файла свойства веб-сайта. Включает свойства environmentSettings.databases. Передать объект в эту функцию невозможно. Visual Studio создает JSON-файл конфигурации для всех веб-проектов и хранит его в папке PublishScripts вашего решения.

.INPUTS
Нет. Эта функция не получает входные данные из конвейера

.OUTPUTS
Microsoft.WindowsAzure.Commands.SqlDatabase.Services.Server.Database

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases | where connectionStringName
PS C:\> $DatabaseConfig

connectionStringName    : Default Connection
databasename : TestDB1
edition      :
size         : 1
collation    : SQL_Latin1_General_CP1_CI_AS
servertype   : New SQL Database Server
servername   : r040tvt2gx
user         : dbuser
password     : Test.123
location     : West US

PS C:\> Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig

.LINK
Add-AzureSQLDatabases

.LINK
New-AzureSQLDatabase
#>
function Add-AzureSQLDatabase
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Object]
        $DatabaseConfig
    )

    Write-VerboseWithTime 'Add-AzureSQLDatabase: начало'

    # Сбой, если у значения параметра нет свойства serverName или если значение свойства serverName не заполнено.
    if (-not (Test-Member $DatabaseConfig 'serverName') -or -not $DatabaseConfig.serverName)
    {
        throw 'Add-AzureSQLDatabase: имя сервера баз данных (обязательно) отсутствует в значении DatabaseConfig.'
    }

    # Сбой, если у значения параметра нет свойства databasename или если значение свойства databasename не заполнено.
    if (-not (Test-Member $DatabaseConfig 'databaseName') -or -not $DatabaseConfig.databaseName)
    {
        throw 'Add-AzureSQLDatabase: имя базы данных (обязательно) отсутствует в значении DatabaseConfig.'
    }

    $DbServer = $null

    if (Test-HttpsUrl $DatabaseConfig.serverName)
    {
        $absoluteDbServer = $DatabaseConfig.serverName -as [System.Uri]
        $subscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue

        if ($subscription -and $subscription.ServiceEndpoint -and $subscription.SubscriptionId)
        {
            $absoluteDbServerRegex = 'https:\/\/{0}\/{1}\/services\/sqlservers\/servers\/(.+)\.database\.windows\.net\/databases' -f `
                                     $subscription.serviceEndpoint.Host, $subscription.SubscriptionId

            if ($absoluteDbServer -match $absoluteDbServerRegex -and $Matches.Count -eq 2)
            {
                 $DbServer = $Matches[1]
            }
        }
    }

    if (!$DbServer)
    {
        $DbServer = $DatabaseConfig.serverName
    }

    $db = Get-AzureSqlDatabase -ServerName $DbServer -DatabaseName $DatabaseConfig.databaseName -ErrorAction SilentlyContinue

    if ($db)
    {
        Write-HostWithTime ('Create-AzureSQLDatabase: использование существующей базы данных ' + $db.Name)
        $db | Out-String | Write-VerboseWithTime
    }
    else
    {
        $param = New-Object -TypeName Hashtable
        $param.Add('serverName', $DbServer)
        $param.Add('databaseName', $DatabaseConfig.databaseName)

        if ((Test-Member $DatabaseConfig 'size') -and $DatabaseConfig.size)
        {
            $param.Add('MaxSizeGB', $DatabaseConfig.size)
        }
        else
        {
            $param.Add('MaxSizeGB', 1)
        }

        # Если у объекта $DatabaseConfig есть свойство collation с непустым и отличным от NULL значением
        if ((Test-Member $DatabaseConfig 'collation') -and $DatabaseConfig.collation)
        {
            $param.Add('Collation', $DatabaseConfig.collation)
        }

        # Если у объекта $DatabaseConfig есть свойство edition с непустым и отличным от NULL значением
        if ((Test-Member $DatabaseConfig 'edition') -and $DatabaseConfig.edition)
        {
            $param.Add('Edition', $DatabaseConfig.edition)
        }

        # Запись хэш-таблицы в подробный поток
        $param | Out-String | Write-VerboseWithTime
        # Вызов New-AzureSqlDatabase со сплаттингом (выходной поток подавляется)
        $db = New-AzureSqlDatabase @param
    }

    Write-VerboseWithTime 'Add-AzureSQLDatabase: окончание'
    return $db
}
