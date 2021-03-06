function Get-Nothing
{
    <#
      .SYNOPSIS
        Sample Function to return input string.

      .DESCRIPTION

      .EXAMPLE
        Get-Something -Data 'Get me this text'

    #>
    [cmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Low'
    )]
    param
    (
        # The Data parameter is the data that will be returned without transformation.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]
        $Data
    )

    process
    {
        if ($pscmdlet.ShouldProcess($Data))
        {
            Write-Verbose ('Returning the data: {0}' -f $Data)
            Get-PrivateFunction -PrivateData $Data
        }
        else
        {
            Write-Verbose 'oh dear'
        }
    }
}
