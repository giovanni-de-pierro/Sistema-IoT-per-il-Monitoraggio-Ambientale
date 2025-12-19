import azure.functions as func
import json

app = func.FunctionApp()

@app.route(route="GetDevices", auth_level=func.AuthLevel.ANONYMOUS)
def GetDevices(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        json.dumps({"message": "Function app message"}),
        mimetype="application/json",
        status_code=200
    )