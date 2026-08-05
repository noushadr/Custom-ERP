import 'dotenv/config';
import { DataSource } from 'typeorm';

// Standalone DataSource for the TypeORM CLI (migration:generate/run/revert).
// The Nest app itself uses DatabaseModule; this file only exists because the
// CLI can't consume Nest's ConfigModule/autoLoadEntities wiring.
export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT ?? '5432', 10),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: [
    `${__dirname}/../../features/**/domain/entities/*.entity{.ts,.js}`,
  ],
  migrations: [`${__dirname}/../../migrations/*{.ts,.js}`],
  synchronize: false,
});
