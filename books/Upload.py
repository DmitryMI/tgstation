import datetime
import os
import mariadb
import sys
import logging

LOG_FORMAT = '%(asctime)s %(message)s'
logging.basicConfig(format=LOG_FORMAT)
logger = logging.getLogger("TgLibraryUploader")
logger.setLevel("DEBUG")
book_format_string = "&lt;font color=&#39;#000000&#39;&gt;&lt;font face=&#39;Verdana&#39;&gt;"
uploader_ckey = "dmitriymi"


def fix_category_name(category_code: str):
    if category_code == "NonFiction":
        return "Non-Fiction"
    if category_code == "Fiction" or \
            category_code == "Adult" or \
            category_code == "Reference" or \
            category_code == "Religion":
        return category_code
    logger.error(f"Invalid category: {category_code}")
    return None


def file_name_to_book_credentials(file_name: str):
    file_name = file_name.replace(".md", "").strip()
    segments = file_name.split("-")
    if len(segments) != 3:
        logger.error("Cannot parse book info")
        return None, None, None

    author = segments[0].strip()
    title = segments[1].strip()
    category = fix_category_name(segments[2].strip())
    if category is None:
        return None, None, None
    return author, title, category


def get_book_text(file_name: str):
    with open(file_name, "r", encoding="utf-8") as file_in:
        text = file_in.read()
        if not text.startswith("&lt"):
            logger.warning("Inserting default format string...")
            text = f"{book_format_string}\n" + text
        return text


def main():
    try:
        logger.info("Connecting to DB...")
        conn = mariadb.connect(
            user="ss13",
            password="tgstation",
            host="127.0.0.1",
            port=3306,
            database="tgstation"
        )
    except mariadb.Error as e:
        logger.error(f"Error connecting to MariaDB Platform: {e}")
        sys.exit(1)

    logger.info("Connection established.")
    cur = conn.cursor()
    cur.execute("SELECT author,title FROM ss13_library")

    logger.info("Books in the database: ")
    for (author, title) in cur:
        logger.info(f"author: {author}, title: {title}")

    logger.info("Local files: ")
    local_files = os.listdir()
    local_books = [file_name for file_name in local_files if ".md" in file_name]
    for book_file_name in local_books:
        logger.info(book_file_name)
        author_local, title_local, category_local = file_name_to_book_credentials(book_file_name)

        if author_local is None:
            continue

        book_text = get_book_text(book_file_name)

        cur.execute("SELECT author,title,category FROM ss13_library where author=? and title=?",
                    (author_local, title_local))

        book_exists = False
        for (author, title, category) in cur:
            logger.info(f"Book already exists: author: {author}, title: {title}, category: {category}")
            book_exists = True
            break

        if book_exists:
            logger.info(f"Updating text of '{author_local} - {title_local} - {category_local}'...")
            cur.execute("UPDATE ss13_library SET content=? WHERE author=? AND title=?",
                        (book_text, author_local, title_local))
            logger.info(f"{cur.rowcount} rows updated")
        else:
            logger.info(f"Uploading new book: '{author_local} - {title_local} - {category_local}'...")

            now = datetime.datetime.now()
            cur.execute(
                "INSERT INTO ss13_library (author,title,content,category,ckey,datetime,deleted,round_id_created) VALUES(?, ?, ?, ?, ?, ?, ?, ?)",
                (author_local, title_local, book_text, category_local, uploader_ckey, now, None, 1))

            logger.info(f"{cur.rowcount} rows inserted")
    conn.commit()
    conn.close()


if __name__ == "__main__":
    main()
