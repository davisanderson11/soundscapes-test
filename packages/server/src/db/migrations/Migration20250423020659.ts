import { Migration } from '@mikro-orm/migrations';

export class Migration20250423020659 extends Migration {

  override async up(): Promise<void> {
    this.addSql(`create table "quad" ("id" serial primary key, "latitude_minutes" int not null, "longitude_minutes" int not null);`);

    this.addSql(`create table "drop" ("id" serial primary key, "latitude" real not null, "longitude" real not null, "special" boolean not null, "quad_id" int not null);`);

    this.addSql(`create table "user" ("id" serial primary key, "spotify_id" varchar(255) not null, "avatar" varchar(255) not null);`);

    this.addSql(`alter table "drop" add constraint "drop_quad_id_foreign" foreign key ("quad_id") references "quad" ("id") on update cascade;`);
  }

  override async down(): Promise<void> {
    this.addSql(`alter table "drop" drop constraint "drop_quad_id_foreign";`);

    this.addSql(`drop table if exists "quad" cascade;`);

    this.addSql(`drop table if exists "drop" cascade;`);

    this.addSql(`drop table if exists "user" cascade;`);
  }

}
