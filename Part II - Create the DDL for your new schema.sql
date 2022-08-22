-- Guideline #1: here is a list of features and specifications that Udiddit
-- needs in order to support its website and administrative interface:

-- A) Allow new users to register

-- I. Each username has to be unique

-- II. Usernames can be composed of at most 25 characters

CREATE TABLE "users" (
  "user_id" SERIAL PRIMARY KEY,
  "username" VARCHAR(25) CONSTRAINT "unique_user" UNIQUE
);

-- III. Usernames can’t be empty

ALTER TABLE "users" ADD CONSTRAINT "user_not_null" CHECK (LENGTH(username) > 0);

-- B) Allow registered users to create new topics

-- I. Topic names have to be unique

-- II. The topic’s name is at most 30 characters

CREATE TABLE "topics" (
  "topic_id" SERIAL PRIMARY KEY,
  "topic_name" VARCHAR(30) CONSTRAINT "unique_topic_name" UNIQUE,
  "user_id" INTEGER CONSTRAINT "valid_user"
    REFERENCES "users"("user_id") ON DELETE SET NULL
);

-- III. The topic’s name can’t be empty

ALTER TABLE "topics" ADD CONSTRAINT "topic_not_null"
  CHECK (LENGTH(topic_name) > 0);

-- IV. Topics can have an optional description of at most 500 characters

ALTER TABLE "topics" ADD COLUMN "description" VARCHAR(500);

-- C) Allow registered users to create new posts on existing topics

-- I. Posts have a required title of at most 100 characters

-- IV. If a topic gets deleted, all the posts associated with it should be
--automatically deleted too

-- V. If the user who created the post gets deleted, then the post will
-- remain, but it will become dissociated from that user

CREATE TABLE "posts" (
  "post_id" SERIAL PRIMARY KEY,
  "post_title" VARCHAR(100),
  "topic_id" INTEGER CONSTRAINT "valid_topic" REFERENCES
"topics"("topic_id") ON DELETE CASCADE,
  "user_id" INTEGER CONSTRAINT "valid_user" REFERENCES
"users"("user_id") ON DELETE SET NULL
);

ALTER TABLE "posts" ADD CONSTRAINT "topic_not_null"
  CHECK (“topic_id” IS NOT NULL);

-- II. The title of a post can’t be empty

ALTER TABLE "posts" ADD CONSTRAINT "title_not_null"
  CHECK (LENGTH(post_title) > 0);

-- III. Posts should contain either a URL or a text content, but not both.

ALTER TABLE "posts" ADD COLUMN "url" TEXT;

ALTER TABLE "posts" ADD COLUMN "content" TEXT;

  ALTER TABLE "posts" ADD CONSTRAINT "url_or_content" CHECK (("url" IS NULL
AND "content" IS NOT NULL) OR ("url" IS NOT NULL AND "content" IS NULL));

-- D) Allow registered users to comment on existing posts

-- III. If a post gets deleted, all comments associated with it should be
-- automatically deleted too

-- IV. If the user who created the comment gets deleted, then the comment
-- will remain, but it will become dissociated from that user

CREATE TABLE "comments" (
  "comment_id" SERIAL PRIMARY KEY,
  "comment" TEXT,
  "post_id" INTEGER CONSTRAINT "valid_post"
    REFERENCES "posts"("post_id") ON DELETE CASCADE,
  "user_id" INTEGER CONSTRAINT "valid_user"
    REFERENCES "users"("user_id") ON DELETE SET NULL
);

ALTER TABLE "comments" ADD CONSTRAINT "post_id_not_null"
  CHECK (“post_id” IS NOT NULL);

-- I. A comment’s text content can’t be empty

ALTER TABLE "comments" ADD CONSTRAINT "comment_not_null"
  CHECK (LENGTH(comment) > 0);

-- II. Contrary to the current linear comments, the new structure should
-- allow comment threads at arbitrary levels

-- V. If a comment gets deleted, then all its descendants in the thread
-- structure should be automatically deleted too

ALTER TABLE "comments" ADD COLUMN "comment_level" INTEGER
  CHECK ("comment_level" >= 1);

-- My idea is that the first comment has the level 1 and its answers has the
-- level 2 and so on, because after all it all are just comments

-- E) Make sure that a given user can only vote once on a given post

-- II. If the user who cast a vote gets deleted, then all their votes will
-- remain, but will become dissociated from the user

-- III. If a post gets deleted, then all the votes for that post should be
-- automatically deleted too

CREATE TABLE "votes" (
  "user_id" INTEGER CONSTRAINT "valid_user"
    REFERENCES "users"("user_id") ON DELETE SET NULL,
  "post_id" INTEGER CONSTRAINT "valid_post"
    REFERENCES "posts"("post_id") ON DELETE CASCADE,
  "vote" SMALLINT,
  CONSTRAINT "id" PRIMARY KEY ("usuario_id", "post_id"),
  CONSTRAINT "unique_vote" UNIQUE ("post_id", "usuario_id")
);

ALTER TABLE "votes" ADD CONSTRAINT “post_id_not_null”
  CHECK (“post_id” IS NOT NULL);

-- I. Hint: you can store the (up/down) value of the vote as the values 1
-- and -1 respectively

ALTER TABLE "votes" ADD CONSTRAINT "valid_vote" CHECK ("vote" = '-1' OR
"vote" = '1');

-- 2. Guideline #2: here is a list of queries that Udiddit needs in order to
-- support its website and administrative interface. Note that you don’t need
-- to produce the DQL for those queries:
-- they are only provided to guide the design of your new database schema.

-- A) List all users who haven’t logged in in the last year.

CREATE TABLE "log_in" (
  "user_id" INTEGER CONSTRAINT "valid_user" REFERENCES "users"("user_id"),
  "when" TIMESTAMP WITH TIME ZONE
);

-- B) List all users who haven’t created any post

SELECT u.user_id
  FROM posts AS p
 RIGHT JOIN users AS u
 WHERE u.user_id IS NOT IN posts

-- C) Find a user by their username

CREATE INDEX "find_user" ON "users"("username");

-- D) List all topics that don’t have any posts

SELECT t.topic_id
  FROM posts AS p
  RIGHT JOIN topics AS t
  WHERE t.topic_id IS NOT IN posts

-- E) Find a topic by its name

CREATE INDEX "find_topic" ON "topics"("topic_name");

-- F) List the latest 20 posts for a given topic

-- G) List the latest 20 posts made by a given user

ALTER TABLE "posts" ADD COLUMN "when" TIMESTAMP WITH TIME ZONE;

-- H) List all the top-level comments (those that don’t have a parent comment)
-- for a given post

-- I) List all the direct children of a parent comment

CREATE INDEX "parent_comment" ON "comments"("comment_level");

-- J) List the latest 20 comments made by a given user

ALTER TABLE "comments" ADD COLUMN "when" TIMESTAMP WITH TIME ZONE;

-- L) Compute the score of a post, defined as the difference between the
-- number of upvotes and the number of downvotes

CREATE INDEX "find_post" ON "votes"("post_id");

-- Guideline #3: you’ll need to use normalization, various constraints, as
-- well as indexes in your new database schema. You should use named
-- constraints and indexes to make your schema cleaner.

-- Guideline #4: your new database schema will be composed of five (5)
-- tables that should have an auto-incrementing id as their primary key.
