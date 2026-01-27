# Fitness AI MCP Server

A Model Context Protocol (MCP) server that provides AI assistants with context about trainees and tools for generating programs, nutrition advice, and more.

## Features

### Resources (Read-only Context)

The server provides these resources for AI to understand trainee data:

| Resource URI | Description |
|-------------|-------------|
| `trainer://exercises` | Trainer's exercise library |
| `trainer://templates` | Program templates |
| `trainer://dashboard` | Dashboard statistics |
| `trainer://trainees` | List of all trainees |
| `trainee://{id}/profile` | Trainee profile, goals, preferences |
| `trainee://{id}/program` | Current active program |
| `trainee://{id}/logs` | Recent workout/nutrition logs |
| `trainee://{id}/progress` | Weight trends and metrics |
| `trainee://{id}/nutrition` | Nutrition goals and intake |
| `trainee://{id}/summary` | Complete context summary |

### Tools (Actions with Trainer Approval)

All tools create **drafts/suggestions** that require trainer approval:

#### Program Generation
- `generate_program_draft` - Create a workout program based on trainee goals
- `suggest_program_modifications` - Suggest changes to existing programs

#### Nutrition Advisory
- `suggest_macro_adjustment` - Recommend macro changes based on progress
- `analyze_nutrition_compliance` - Analyze nutrition patterns
- `generate_meal_suggestions` - Suggest meals for remaining macros

#### Message Drafting
- `draft_checkin_message` - Draft check-in messages for trainees
- `draft_feedback_message` - Draft feedback on specific logs
- `draft_program_intro_message` - Draft program introduction messages

#### Analysis
- `analyze_trainee_progress` - Comprehensive progress analysis
- `compare_trainees` - Compare metrics across trainees
- `identify_at_risk_trainees` - Find trainees needing attention
- `generate_weekly_summary` - Weekly overview with action items

## Setup

### Prerequisites

- Python 3.11+
- Django backend running
- Trainer JWT token

### Installation

```bash
cd backend/mcp_server
pip install -r requirements.txt
```

### Configuration

Create a `.env` file or set environment variables:

```bash
# Required: Trainer's JWT token
export TRAINER_JWT_TOKEN="your_jwt_token_here"

# Optional: Django API URL (defaults to http://localhost:8000/api)
export DJANGO_API_BASE_URL="http://localhost:8000/api"
```

### Running the Server

```bash
# Direct execution
python server.py

# Or with uvx (recommended)
uvx mcp run server.py
```

## Claude Desktop Integration

Add this to your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "fitness-ai": {
      "command": "python",
      "args": ["/path/to/backend/mcp_server/server.py"],
      "env": {
        "TRAINER_JWT_TOKEN": "your_jwt_token_here",
        "DJANGO_API_BASE_URL": "http://localhost:8000/api"
      }
    }
  }
}
```

Or using uvx:

```json
{
  "mcpServers": {
    "fitness-ai": {
      "command": "uvx",
      "args": ["mcp", "run", "/path/to/backend/mcp_server/server.py"],
      "env": {
        "TRAINER_JWT_TOKEN": "your_jwt_token_here"
      }
    }
  }
}
```

## In-App Integration

For integrating AI chat directly in the Flutter app, you'll need to:

1. **Backend Proxy Endpoint**: Create an endpoint that forwards requests to Claude API with MCP context
2. **Token Management**: The app should pass the trainer's JWT token to the MCP server
3. **UI**: Build a chat interface in the trainer dashboard

See the implementation guide below.

## Security

- **Authentication**: The MCP server uses the trainer's JWT token to authenticate with Django
- **Scoped Access**: Trainers can only access their own trainees' data
- **Approval Required**: All tools create drafts that require trainer review
- **No Direct Modifications**: The server cannot directly modify data without trainer action

## Example Usage in Claude Desktop

Once configured, you can ask Claude questions like:

```
"Show me John's progress over the last 30 days"

"Generate a 12-week muscle building program for Sarah"

"Which of my trainees need attention this week?"

"Draft a check-in message for Mike about his nutrition"

"Analyze the compliance rates across all my trainees"
```

## Development

### Project Structure

```
mcp_server/
├── __init__.py
├── server.py           # Main MCP server
├── config.py           # Configuration
├── api_client.py       # Django API client
├── requirements.txt
├── README.md
├── resources/          # MCP Resources
│   ├── __init__.py
│   ├── trainee.py      # Trainee data resources
│   └── trainer.py      # Trainer data resources
└── tools/              # MCP Tools
    ├── __init__.py
    ├── program_generator.py
    ├── nutrition_advisor.py
    ├── message_drafter.py
    └── analysis.py
```

### Adding New Resources

1. Add resource URI to `list_resources()` in `server.py`
2. Add handler in `read_resource()`
3. Implement data fetching in `resources/` module

### Adding New Tools

1. Add tool definition to `list_tools()` in `server.py`
2. Add handler routing in `call_tool()`
3. Implement tool logic in `tools/` module
4. Ensure all tools return `requires_approval: True` for actions

## Troubleshooting

### "No JWT token provided"
Set the `TRAINER_JWT_TOKEN` environment variable with a valid trainer token.

### "Could not verify authentication"
- Check that the Django backend is running
- Verify the token is valid and not expired
- Ensure the token belongs to a TRAINER role user

### Resources not loading
- Check Django API is accessible
- Verify trainer has trainees assigned
- Check API endpoint permissions

## License

Proprietary - Fitness AI
