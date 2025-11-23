require("dotenv").config();

// Determine if we're in development mode
const isDevelopment = process.env.NODE_ENV !== "production" && !process.env.FORCE_PRODUCTION_DB;

// Use localhost for development, .env values for production
let dbHost, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_SSL;

if (isDevelopment) {
	// Force localhost for development (Docker Postgres)
	console.log("🔧 Development mode: Using local Docker Postgres");
	dbHost = "localhost";
	DB_PORT = 5432;
	DB_NAME = "postgres";
	DB_USER = "postgres";
	DB_PASSWORD = "Karldarn25!";
	DB_SSL = "false";
} else {
	// Use Supabase for production deployment
	console.log("🚀 Production mode: Using Supabase database");
	// Use hostname from .env or fallback to Supabase host
	dbHost = process.env.DB_HOST || "db.mxfuvioxlsnegqbczsjm.supabase.co";
	DB_PORT = process.env.DB_PORT || 6543; // Connection pooling port
	DB_NAME = process.env.DB_NAME || "postgres";
	DB_USER = process.env.DB_USER || "postgres";
	DB_PASSWORD = process.env.DB_PASSWORD || "Karldarn25!";
	DB_SSL = process.env.DB_SSL || "true"; // Supabase requires SSL
}

console.log(`🔌 Database Host: ${dbHost}`);
console.log(`📊 Database: ${DB_NAME}, User: ${DB_USER}`);

const sslEnabled = DB_SSL === "true";

// Build connection URI for better DNS resolution
// For connection pooling (port 6543), add pgbouncer parameter
const encodedPassword = encodeURIComponent(DB_PASSWORD);
const poolerParam = DB_PORT === 6543 ? "?pgbouncer=true" : "";
const connectionUri = `postgresql://${DB_USER}:${encodedPassword}@${dbHost}:${DB_PORT}/${DB_NAME}${poolerParam}`;

module.exports = {
	HOST: dbHost,
	USER: DB_USER,
	PASSWORD: DB_PASSWORD,
	DB: DB_NAME,
	PORT: DB_PORT,
	URI: connectionUri, // Add URI for connection string format
	dialect: "postgres",
	dialectOptions: sslEnabled
		? {
				ssl: {
					require: true,
					rejectUnauthorized: false,
				},
		  }
		: {},
	pool: {
		max: 5,
		min: 0,
		acquire: 30000,
		idle: 10000,
	},
};
