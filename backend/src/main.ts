import { join } from 'path';
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const config = app.get(ConfigService);

  app.use(helmet());
  // Never wide-open: falls back to the local Flutter-web dev origin when
  // CORS_ORIGIN isn't set, rather than defaulting to "*".
  const corsOrigin = config.get<string>('corsOrigin');
  app.enableCors({
    origin: corsOrigin
      ? corsOrigin.split(',').map((origin) => origin.trim())
      : 'http://localhost:5050',
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads',
  });

  await app.listen(config.get<number>('port') ?? 3000);
}
void bootstrap();
