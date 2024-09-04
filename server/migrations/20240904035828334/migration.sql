BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "drop" (
    "id" bigserial PRIMARY KEY,
    "lat" double precision NOT NULL,
    "lng" double precision NOT NULL,
    "special" boolean NOT NULL,
    "quadId" bigint NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "quad" (
    "id" bigserial PRIMARY KEY,
    "lat" bigint NOT NULL,
    "lng" bigint NOT NULL
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "drop"
    ADD CONSTRAINT "drop_fk_0"
    FOREIGN KEY("quadId")
    REFERENCES "quad"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR soundscapes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('soundscapes', '20240904035828334', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240904035828334', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
