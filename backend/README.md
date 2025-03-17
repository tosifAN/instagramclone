
## Tech Stack

- **Go**: Programming language
- **Gin**: Web framework for routing
- **GORM**: ORM library to deal with the database
- **PostgreSQL**: Database
- **JWT**: Authentication
- **bcrypt**: for hashing

## Project Structure

```
backend/
├── handlers/      # Request handlers
├── middleware/    # Custom middleware
├── models/        # Database models
├── .env          # Environment variables
├── main.go       # Entry point
└── 
```

## Setup Instructions

3. Install Go dependencies:
```bash
go mod tidy
```

4. Set up environment variables:
- Copy `.env.example` to `.env`
- Update values as needed

5. Run the application:
```bash
go run main.go
```

The server will start at `http://localhost:8080`
