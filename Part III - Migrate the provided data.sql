-- Exploring the initial database

-- TABLE "bad_comments"
-- COLUMNS "id" SERIAL PRIMARY KEY,
--         "username" VARCHAR(50),
--         "post_id" BIGINT,
--         "text_content" TEXT

-- TABLE "bad_posts"
-- COLUMNS "id" SERIAL PRIMARY KEY,
--         "topic" VARCHAR(50),
--         "username" VARCHAR(50),
--         "title" VARCHAR(150),
--         "url" VARCHAR(4000) DEFAULT NULL,
--         "text_content" TEXT,
--         "upvotes" TEXT,
--         "downvotes" TEXT

-- First of all, I'm going to migrate the user data, because without it it's
-- impossible to interact on the social network. Then I'll migrate the rest as
-- if it were a tree and its ramifications

CREATE TABLE "users_provisional_table" (
  "id" SERIAL PRIMARY KEY,
  "user" VARCHAR(25)
);

INSERT INTO "users_provisional_table"("user") (
  SELECT username
    FROM bad_comments
  );

INSERT INTO "users_provisional_table"("user") (
  SELECT username
    FROM bad_posts
);

INSERT INTO "users_provisional_table"("user") (
  SELECT regexp_split_to_table("upvotes", ',')
    FROM bad_posts
);

INSERT INTO "users_provisional_table"("user") (
  SELECT regexp_split_to_table("downvotes", ',')
    FROM bad_posts
);

INSERT INTO "users"("username") (
  SELECT DISTINCT user
    FROM users_provisional_table
);

DROP TABLE "users_provisional_table";

-- Topics

-- 1.Topic descriptions can all be empty

INSERT INTO "topics"("topic_name", "description")
  SELECT DISTINCT topic,
                  NULL AS description
    FROM bad_posts;

-- Posts

INSERT INTO "posts"("post_id", "post_title", "url", "content",
"topic_id", "user_id")
  SELECT bp.id,
         LEFT(bp.title, 100),
         bp.url,
         bp.text_content,
         t.topico_id AS topico_id,
         u.user_id AS user_id
    FROM bad_posts AS bp
    JOIN topics AS t
      ON bp.topic = t.topic_name
    JOIN users AS u
      ON bp.username = u.username;

INSERT INTO "posts"("post_id", "post_title", "url", "content",
"topic_id", "user_id")
  SELECT bp.id,
         bp.title,
         bp.url,
         bp.text_content,
         t.topic_id AS topic_id,
         u.user_id AS user_id
    FROM bad_posts AS bp
    JOIN topics AS t
      ON bp.topic = t.topic_name
    JOIN users AS u
      ON bp.username = u.username
   WHERE LENGTH(bp.title) <= 100;

-- Comments

-- 2. Since the bad_comments table doesn’t have the threading feature, you can
-- migrate all comments as top-level comments, i.e. without a parent

INSERT INTO "comments"("comment", "post_id", "user_id",
"comment_level")
  SELECT bc.text_content,
         bc.post_id,
         u.user_id,
         '1'
    FROM bad_comments AS bc
    JOIN users AS u
      ON bc.username = u.username;

-- Votes

INSERT INTO "votes"("user_id", "post_id", "vote")
  SELECT u.user_id,
         vp.post_id,
         '1'
    FROM (SELECT id AS post_id,
                 regexp_split_to_table("upvotes", ',') AS user
            FROM bad_posts) AS vp
    JOIN users AS u
      ON vp.user = u.username;

INSERT INTO "votes"("user_id", "post_id", "vote")
  SELECT u.user_id,
         vn.post_id,
         '-1'
    FROM (SELECT id AS post_id,
                 regexp_split_to_table("downvotes", ',') AS user
            FROM bad_posts) AS vn
    JOIN user AS u
      ON vn.user = u.username;
