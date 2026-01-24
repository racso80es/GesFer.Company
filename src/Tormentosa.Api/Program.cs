using System.Diagnostics;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// Configurar logging personalizado hacia activity_stream.jsonl
var storagePath = Environment.GetEnvironmentVariable("STORAGE_PATH") ?? "/storage";
var activityStreamPath = Path.Combine(storagePath, "Tekton", "Logs", "activity_stream.jsonl");

builder.Services.AddSingleton<IActivityLogger>(sp =>
    new ActivityStreamLogger(activityStreamPath));

var app = builder.Build();

// Endpoint de salud
app.MapGet("/", () => new
{
    service = "Tormentosa.Api",
    version = "1.0.0",
    status = "running",
    endpoint = "/SyncAudios"
});

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

// Endpoint principal: SyncAudios
app.MapGet("/SyncAudios", async (IActivityLogger logger, ILogger<Program> appLogger) =>
{
    var timestamp = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ");
    var auditStamp = $"LATIDO_{DateTime.UtcNow:yyyyMMdd_HHmmss}";

    try
    {
        appLogger.LogInformation("Iniciando sincronización de audios...");

        // Ruta al script en el almacén: /storage/Tekton/Tools/Ingesta_Audio.ps1
        var scriptPath = Path.Combine(storagePath, "Tekton", "Tools", "Ingesta_Audio.ps1");

        if (!File.Exists(scriptPath))
        {
            var errorMsg = $"Script no encontrado: {scriptPath}";
            appLogger.LogError(errorMsg);

            await logger.LogAsync(new
            {
                timestamp,
                status = "Failure",
                source_tool = "SYNC_AUDIOS_API",
                audit_stamp = auditStamp,
                payload = new
                {
                    error = errorMsg,
                    script_path = scriptPath
                }
            });

            return Results.NotFound(new { error = errorMsg, scriptPath });
        }

        // Ejecutar script PowerShell
        var processStartInfo = new ProcessStartInfo
        {
            FileName = "pwsh",
            Arguments = $"-File \"{scriptPath}\"",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        var sw = System.Diagnostics.Stopwatch.StartNew();
        using var process = Process.Start(processStartInfo);
        if (process == null)
        {
            throw new Exception("No se pudo iniciar el proceso PowerShell");
        }

        var output = await process.StandardOutput.ReadToEndAsync();
        var error = await process.StandardError.ReadToEndAsync();

        await process.WaitForExitAsync();
        sw.Stop();

        var success = process.ExitCode == 0;
        var status = success ? "Success" : "Failure";

        appLogger.LogInformation($"Script ejecutado. ExitCode: {process.ExitCode}");

        // Registrar en activity_stream.jsonl
        await logger.LogAsync(new
        {
            timestamp,
            status,
            source_tool = "SYNC_AUDIOS_API",
            audit_stamp = auditStamp,
            payload = new
            {
                script_path = scriptPath,
                exit_code = process.ExitCode,
                output = output.Trim(),
                error = error.Trim(),
                execution_time_ms = sw.Elapsed.TotalMilliseconds
            }
        });

        if (success)
        {
            return Results.Ok(new
            {
                status = "success",
                message = "Sincronización de audios completada",
                audit_stamp = auditStamp,
                output = output.Trim()
            });
        }
        else
        {
            return Results.BadRequest(new
            {
                status = "error",
                message = "Error en la sincronización de audios",
                audit_stamp = auditStamp,
                error = error.Trim(),
                output = output.Trim()
            });
        }
    }
    catch (Exception ex)
    {
        appLogger.LogError(ex, "Error al ejecutar SyncAudios");

        await logger.LogAsync(new
        {
            timestamp,
            status = "Failure",
            source_tool = "SYNC_AUDIOS_API",
            audit_stamp = auditStamp,
            payload = new
            {
                error = ex.Message,
                stack_trace = ex.StackTrace
            }
        });

        return Results.Problem(
            detail: ex.Message,
            statusCode: 500
        );
    }
});

app.Run();

// Interfaz para el logger de actividad
public interface IActivityLogger
{
    Task LogAsync(object data);
}

// Implementación del logger hacia activity_stream.jsonl
public class ActivityStreamLogger : IActivityLogger
{
    private readonly string _filePath;
    private readonly SemaphoreSlim _semaphore = new(1, 1);

    public ActivityStreamLogger(string filePath)
    {
        _filePath = filePath;

        // Asegurar que el directorio existe
        var directory = Path.GetDirectoryName(_filePath);
        if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
        {
            Directory.CreateDirectory(directory);
        }
    }

    public async Task LogAsync(object data)
    {
        await _semaphore.WaitAsync();
        try
        {
            var json = JsonSerializer.Serialize(data, new JsonSerializerOptions
            {
                WriteIndented = false
            });

            await File.AppendAllTextAsync(_filePath, json + Environment.NewLine);
        }
        finally
        {
            _semaphore.Release();
        }
    }
}
