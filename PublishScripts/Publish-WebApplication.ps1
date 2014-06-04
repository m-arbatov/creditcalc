#Requires -Version 3.0

<#
.SYNOPSIS
Создает и развертывает веб-сайты, виртуальные машины, базы данных SQL и учетные записи хранения Windows Azure для веб-проекта Visual Studio.

.DESCRIPTION
Скрипт Publish-WebApplication.ps1 создает и (необязательно) развертывает ресурсы Windows Azure, указанные в веб-проекте Visual Studio. Он может создавать веб-сайты Windows Azure, виртуальные машины, базы данных SQL и учетные записи хранения.

To manage the entire application lifecycle of your web application in this script, implement the placeholder functions New-WebDeployPackage and Test-WebApplication.

Если указан параметр WebDeployPackage с действительным ZIP-файлом пакета веб-развертывания, Publish-WebApplication.ps1 также развертывает создаваемые им веб-страницы или виртуальные машины.

Для этого скрипта требуется Windows PowerShell версии 3.0 или более поздней и Windows Azure PowerShell версии 0.7.4 или более поздней. Сведения об установке Windows Azure PowerShell и модуля Azure см. по адресу http://go.microsoft.com/fwlink/?LinkID=350552. Чтобы узнать версию используемого модуля Azure, введите: (Get-Module -Name Azure -ListAvailable).version Чтобы узнать версию Windows PowerShell, введите: $PSVersionTable.PSVersion

Перед выполнением этого скрипта выполните командлет Add-AzureAccount, чтобы предоставить Windows PowerShell учетные данные вашей учетной записи Windows Azure. Для создания баз данных SQL также необходим существующий сервер баз данных SQL Windows Azure. Чтобы создать базу данных SQL, используйте командлет New-AzureSqlDatabaseServer в модуле Azure.

Also, if you have never run a script, use the Set-ExecutionPolicy cmdlet to an execution policy that allows you to run scripts. To run this cmdlet, start Windows PowerShell with the 'Run as administrator' option.

Этот скрипт Publish-WebApplication.ps1 использует JSON-файл конфигурации, создаваемый Visual Studio при создании веб-проекта. JSON-файле находится в папке PublishScripts вашего решения Visual Studio.

Объект databases в JSON-файле конфигурации можно удалить или изменить. Не удаляйте объекты website или cloudservice или их атрибуты. Тем не менее, можно удалить объект databases целиком или удалить атрибуты, представляющие базу данных. Чтобы создать базу данных SQL, но не развертывать ее, удалите атрибут "connectionStringName" или его значение.

Также используются функции в модуле скрипта Windows PowerShell AzureWebAppPublishModule.psm1 для создания ресурсов в подписке Windows Azure. Копию этого модуля скрипта можно найти в папке PublishScripts решения Visual Studio.

Скрипт Publish-WebApplication.ps1 можно использовать как есть или изменить согласно имеющимся потребностям. Функции в модуле скрипта AzureWebAppPublishModule.psm1 также можно использовать независимо от скрипта и редактировать. Например, можно использовать функцию Invoke-AzureWebRequest для вызова любого интерфейса REST API в веб-службе Windows Azure.

При наличии скрипта, создающего необходимые ресурсы Windows Azure, его можно использовать неоднократно для создания сред и ресурсов в Windows Azure.

Обновления этого скрипта см. по адресу http://go.microsoft.com/fwlink/?LinkId=391217.
Чтобы добавить поддержку в построение проекта веб-приложения, см. документацию MSBuild: http://go.microsoft.com/fwlink/?LinkId=391339 
Чтобы добавить поддержку для выполнения модульных тестов проекта веб-приложения, см. документацию VSTest.Console: http://go.microsoft.com/fwlink/?LinkId=391340 

Условия лицензии WebDeploy: http://go.microsoft.com/fwlink/?LinkID=389744 

.PARAMETER Configuration
Указывает путь и имя JSON-файла конфигурации, создаваемого Visual Studio. Это обязательный параметр. Этот файл можно найти в папке PublishScripts решения Visual Studio. В JSON-файлах конфигурации можно изменять значения атрибутов и удалять необязательные объекты базы данных SQL. Для правильного выполнения скрипта можно удалять объекты базы данных SQL в файлах конфигурации веб-сайтов и виртуальных машин. Удаление объектов и атрибутов веб-сайта и облачной службы невозможно. Если пользователь не желает создавать или применять базу данных SQL к строке подключения при публикации, следует убедиться, что атрибут "connectionStringName" в объекте базы данных SQL пуст, или удалить весь объект базы данных SQL.

ПРИМЕЧАНИЕ. Этот скрипт поддерживает только файлы виртуальных дисков Windows (VHD) для виртуальных машин. Чтобы использовать формат Linux (VHD), измените скрипт таким образом, чтобы он вызывал командлет с параметром Linux, такой как New-AzureQuickVM или New-WAPackVM.

.PARAMETER SubscriptionName
Указывает имя подписки в вашей учетной записи Windows Azure. Это необязательный параметр. По умолчанию — текущая подписка (Get-AzureSubscription -Current). Если указана не текущая подписка, скрипт временно делает указанную подписку текущей, но восстанавливает статус текущей подписки перед завершением скрипта. Если до завершения скрипта возникает ошибка, текущей может остаться указанная подписка.

.PARAMETER WebDeployPackage
Указывает путь и имя ZIP-файла пакета веб-развертывания, созданного Visual Studio. Это необязательный параметр.

Если указан действительный пакет веб-развертывания, этот скрипт использует MsDeploy.exe и пакет веб-развертывания для развертывания веб-сайта.

Сведения о создании ZIP-файла пакета веб-развертывания см. в разделе "Практическое руководство. Создание пакета веб-развертывания в Visual Studio" по адресу: http://go.microsoft.com/fwlink/?LinkId=391353.

Сведения об MSDeploy.exe см. в справочнике по командной строке для веб-развертывания по адресу http://go.microsoft.com/fwlink/?LinkId=391354 

.PARAMETER AllowUntrusted
Разрешает недоверенные SSL-соединения с конечной точкой веб-развертывания на виртуальной машине. Этот параметр используется в вызове MSDeploy.exe. Это необязательный параметр. Значение по умолчанию — False. Этот параметр действует только при включенном параметре WebDeployPackage с действительным значением ZIP-файла. Сведения об MSDeploy.exe см. в справочнике по командной строке для веб-развертывания по адресу http://go.microsoft.com/fwlink/?LinkId=391354 

.PARAMETER VMPassword
Указывает имя пользователя и пароль для администратора виртуальной машины Windows Azure, создаваемой скриптом. Этот параметр принимает хэш-таблицу с ключами Name и Password, например:
@{Name = "admin"; Password = "pa$$word"}

Это необязательный параметр. Если он опущен, по умолчанию используются значения имени пользователя виртуальной машины и пароля в JSON-файле конфигурации.

Этот параметр действует только при использовании JSON-файла конфигурации для облачной службы, которая включает виртуальные машины.

.PARAMETER DatabaseServerPassword
Sets the password for a Windows Azure SQL database server. This parameter takes an array of hash tables with Name (SQL database server name) and Password keys. Enter one hash table for each database server that your SQL databases use.

Это необязательный параметр. По умолчанию устанавливается пароль сервера баз данных из JSON-файла конфигурации, создаваемого Visual Studio.

Это значение действует, когда JSON-файл конфигурации включает атрибуты databases и serverName и ключ Name в хэш-таблице совпадает со значением serverName.

.INPUTS
Нет. Передать в этот скрипт значения параметров невозможно.

.OUTPUTS
Нет. Этот скрипт не возвращает объекты. Для статуса скрипта используйте параметр Verbose.

.EXAMPLE
PS C:\> C:\Scripts\Publish-WebApplication.ps1 -Configuration C:\Documents\Azure\WebProject-WAWS-dev.json

.EXAMPLE
PS C:\> C:\Scripts\Publish-WebApplication.ps1 `
-Configuration C:\Documents\Azure\ADWebApp-VM-prod.json `
-Subscription Contoso '
-WebDeployPackage C:\Documents\Azure\ADWebApp.zip `
-AllowUntrusted `
-DatabaseServerPassword @{Name='dbServerName';Password='adminPassword'} `
-Verbose

.EXAMPLE
PS C:\> $admin = @{name="admin";password="Test123"}
PS C:\> C:\Scripts\Publish-WebApplication.ps1 `
-Configuration C:\Documents\Azure\ADVM-VM-test.json `
-SubscriptionName Contoso `
-WebDeployPackage C:\Documents\Azure\ADVM.zip `
-VMPaassword = @{name = "vmAdmin"; password = "pa$$word"} `
-DatabaseServerPassword = @{Name='server1';Password='adminPassword1'}, @{Name='server2';Password='adminPassword2'} `
-Verbose

.LINK
New-AzureVM

.LINK
New-AzureStorageAccount

.LINK
New-AzureWebsite

.LINK
Add-AzureEndpoint
#>
[CmdletBinding(DefaultParameterSetName = 'None', HelpUri = 'http://go.microsoft.com/fwlink/?LinkID=391696')]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]
    $Configuration,

    [Parameter(Mandatory = $false)]
    [String]
    $SubscriptionName,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]
    $WebDeployPackage,

    [Parameter(Mandatory = $false)]
    [Switch]
    $AllowUntrusted,

    [Parameter(Mandatory = $false, ParameterSetName = 'VM')]
    [ValidateScript( { $_.Contains('Name') -and $_.Contains('Password') } )]
    [Hashtable]
    $VMPassword,

    [Parameter(Mandatory = $false, ParameterSetName = 'WebSite')]
    [ValidateScript({ !($_ | Where-Object { !$_.Contains('Name') -or !$_.Contains('Password')}) })]
    [Hashtable[]]
    $DatabaseServerPassword,

    [Parameter(Mandatory = $false)]
    [Switch]
    $SendHostMessagesToOutput = $false
)


function New-WebDeployPackage
{
    #Запишите функцию для построения и упаковки вашего веб-приложения

    #Для построения веб-приложения используйте MsBuild.exe. Справочные сведения см. в справочнике по командной строке для MSBuild по адресу: http://go.microsoft.com/fwlink/?LinkId=391339
}

function Test-WebApplication
{
    #Измените эту функцию для выполнения модульного теста вашего веб-приложения

    #Запишите функцию для выполнения модульных тестов вашего веб-приложения с помощью VSTest.Console.exe. Справочные сведения см. в справочнике по командной строке для VSTest.Console по адресу http://go.microsoft.com/fwlink/?LinkId=391340
}

function New-AzureWebApplicationEnvironment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Config,

        [Parameter (Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMPassword,

        [Parameter (Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword
    )
   
    $VMInfo = $null

    # Если JSON-файл имеет элемент webSite
    if ($Config.IsAzureWebSite)
    {
        Add-AzureWebsite -Name $Config.name -Location $Config.location | Out-String | Write-HostWithTime
        # Создайте базу данных SQL. Строка подключения используется для развертывания.
    }
    else
    {
        $VMInfo = New-AzureVMEnvironment `
            -CloudServiceConfiguration $Config.cloudService `
            -VMPassword $VMPassword
    } 

    $connectionString = New-Object -TypeName Hashtable
    
    if ($Config.Contains('databases'))
    {
        @($Config.databases) |
            Where-Object {$_.connectionStringName -ne ''} |
            Add-AzureSQLDatabases -DatabaseServerPassword $DatabaseServerPassword -CreateDatabase:$Config.IsAzureWebSite |
            ForEach-Object { $connectionString.Add($_.Name, $_.ConnectionString) }           
    }
    
    return @{ConnectionString = $connectionString; VMInfo = $VMInfo}   
}

function Publish-AzureWebApplication
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Config,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,
        
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMInfo           
    )

    if ($Config.IsAzureWebSite)
    {
        if ($ConnectionString -and $ConnectionString.Count -gt 0)
        {
            Publish-AzureWebsiteProject `
                -Name $Config.name `
                -Package $WebDeployPackage `
                -ConnectionString $ConnectionString
        }
        else
        {
            Publish-AzureWebsiteProject `
                -Name $Config.name `
                -Package $WebDeployPackage
        }
    }
    else
    {
        $waitingTime = $VMWebDeployWaitTime

        $result = $null
        $attempts = 0
        $allAttempts = 60
        do 
        {
            $result = Publish-WebPackageToVM `
                -VMDnsName $VMInfo.VMUrl `
                -IisWebApplicationName $Config.webDeployParameters.IisWebApplicationName `
                -WebDeployPackage $WebDeployPackage `
                -UserName $VMInfo.UserName `
                -UserPassword $VMInfo.Password `
                -AllowUntrusted:$AllowUntrusted `
                -ConnectionString $ConnectionString
             
            if ($result)
            {
                Write-VerboseWithTime ($scriptName + ' Публикация в виртуальную машину выполнена успешно.')
            }
            elseif ($VMInfo.IsNewCreatedVM -and !$Config.cloudService.virtualMachine.enableWebDeployExtension)
            {
                Write-VerboseWithTime ($scriptName + ' Необходимо установить для "enableWebDeployExtension" значение $true.')
            }
            elseif (!$VMInfo.IsNewCreatedVM)
            {
                Write-VerboseWithTime ($scriptName + ' Существующая виртуальная машина не поддерживает Web Deploy.')
            }
            else
            {
                Write-VerboseWithTime ($scriptName + " Сбой публикации в виртуальную машину. Попытка $($attempts + 1) из $allAttempts.")
                Write-VerboseWithTime ($scriptName + " Публикация в виртуальную машину начнется через $waitingTime с.")
                
                Start-Sleep -Seconds $waitingTime
            }
             
             $attempts++
        
             #Повторите попытку публикации для созданной виртуальной машины с установленным Web Deploy. 
        } While( !$result -and $VMInfo.IsNewCreatedVM -and $attempts -lt $allAttempts -and $Config.cloudService.virtualMachine.enableWebDeployExtension)
        
        if (!$result)
        {                    
            Write-Warning 'Publishing to the virtual machine failed. This can be caused by an untrusted or invalid certificate.  You can specify �AllowUntrusted to accept untrusted or invalid certificates.'
            throw ($scriptName + ' Сбой публикации в виртуальную машину.')
        }
    }
}


# Основная подпрограмма скрипта
Set-StrictMode -Version 3

# Импорт текущей версии модуля AzureWebAppPublishModule.psm1
Remove-Module AzureWebAppPublishModule -ErrorAction SilentlyContinue
$scriptDirectory = Split-Path -Parent $PSCmdlet.MyInvocation.MyCommand.Definition
Import-Module ($scriptDirectory + '\AzureWebAppPublishModule.psm1') -Scope Local -Verbose:$false

New-Variable -Name VMWebDeployWaitTime -Value 30 -Option Constant -Scope Script 
New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
New-Variable -Name SendHostMessagesToOutput -Value $SendHostMessagesToOutput -Scope Global -Force

try
{
    $originalErrorActionPreference = $Global:ErrorActionPreference
    $originalVerbosePreference = $Global:VerbosePreference
    
    if ($PSBoundParameters['Verbose'])
    {
        $Global:VerbosePreference = 'Continue'
    }
    
    $scriptName = $MyInvocation.MyCommand.Name + ':'
    
    Write-VerboseWithTime ($scriptName + ' Начать')
    
    $Global:ErrorActionPreference = 'Stop'
    Write-VerboseWithTime ('{0} для $ErrorActionPreference установлено значение {1}' -f $scriptName, $ErrorActionPreference)
    
    Write-Debug ('{0}: $PSCmdlet.ParameterSetName = {1}' -f $scriptName, $PSCmdlet.ParameterSetName)

    # Сохранение текущей подписки. Позднее в данном скрипте она будет восстановлена в статусе текущей
    Backup-Subscription -UserSpecifiedSubscription $SubscriptionName
    
    # Проверка наличия модуля Azure версии 0.7.4 или более поздней.
    if (-not (Test-AzureModule))
    {
         throw 'Ваша версия Windows Azure Powershell устарела. Чтобы установить последнюю версию, перейдите по адресу http://go.microsoft.com/fwlink/?LinkID=320552.'
    }
    
    if ($SubscriptionName)
    {

        # Если предоставлено имя подписки, проверяется существование этой подписки в учетной записи.
        if (!(Get-AzureSubscription -SubscriptionName $SubscriptionName))
        {
            throw ("{0}: не удается найти имя подписки $SubscriptionName" -f $scriptName)

        }

        # Делает указанную подписку текущей.
        Select-AzureSubscription -SubscriptionName $SubscriptionName | Out-Null

        Write-VerboseWithTime ('{0}: установлена подписка {1}' -f $scriptName, $SubscriptionName)
    }

    $Config = Read-ConfigFile $Configuration -HasWebDeployPackage:([Bool]$WebDeployPackage)

    #Выполните построение и упаковку вашего веб-приложения
    #New-WebDeployPackage

    #Выполните модульный тест вашего веб-приложения
    #Test-WebApplication

    #Создайте среду Azure, описанную в JSON-файле конфигурации
    $newEnvironmentResult = New-AzureWebApplicationEnvironment -Config $Config -DatabaseServerPassword $DatabaseServerPassword -VMPassword $VMPassword

    #Развертывание пакета веб-приложения, если пользователем указано $WebDeployPackage 
    if($WebDeployPackage)
    {
        Publish-AzureWebApplication `
            -Config $Config `
            -ConnectionString $newEnvironmentResult.ConnectionString `
            -WebDeployPackage $WebDeployPackage `
            -VMInfo $newEnvironmentResult.VMInfo
    }
}
finally
{
    $Global:ErrorActionPreference = $originalErrorActionPreference
    $Global:VerbosePreference = $originalVerbosePreference

    # Восстановление исходной текущей подписки в статусе текущей
    Restore-Subscription

    Write-Output $Global:AzureWebAppPublishOutput    
    $Global:AzureWebAppPublishOutput = @()
}
