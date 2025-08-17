-- IMDB-like Database Schema
-- Initialize database for movie/TV show metadata

-- Create database
DROP DATABASE IF EXISTS dbmcp;
CREATE DATABASE dbmcp;
USE dbmcp;

-- People table (actors, directors, writers, etc.)
CREATE TABLE people (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    birth_date DATE,
    death_date DATE,
    biography TEXT,
    profile_image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
);

-- Genres table
CREATE TABLE genres (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- Production companies
CREATE TABLE production_companies (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100),
    founded_year INT,
    logo_url VARCHAR(500),
    website VARCHAR(255)
);

-- Movies table
CREATE TABLE movies (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    original_title VARCHAR(255),
    release_date DATE,
    runtime_minutes INT,
    plot_summary TEXT,
    tagline VARCHAR(500),
    budget DECIMAL(15,2),
    box_office DECIMAL(15,2),
    imdb_rating DECIMAL(3,1),
    imdb_votes INT,
    poster_url VARCHAR(500),
    backdrop_url VARCHAR(500),
    status ENUM('rumored', 'planned', 'in_production', 'post_production', 'released', 'canceled') DEFAULT 'released',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_title (title),
    INDEX idx_release_date (release_date),
    INDEX idx_rating (imdb_rating)
);

-- TV Shows table
CREATE TABLE tv_shows (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    original_title VARCHAR(255),
    first_air_date DATE,
    last_air_date DATE,
    number_of_seasons INT DEFAULT 0,
    number_of_episodes INT DEFAULT 0,
    episode_runtime_minutes INT,
    plot_summary TEXT,
    tagline VARCHAR(500),
    imdb_rating DECIMAL(3,1),
    imdb_votes INT,
    poster_url VARCHAR(500),
    backdrop_url VARCHAR(500),
    status ENUM('returning', 'planned', 'in_production', 'ended', 'canceled', 'pilot') DEFAULT 'ended',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_title (title),
    INDEX idx_first_air_date (first_air_date),
    INDEX idx_rating (imdb_rating)
);

-- TV Seasons table
CREATE TABLE tv_seasons (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tv_show_id INT NOT NULL,
    season_number INT NOT NULL,
    name VARCHAR(255),
    air_date DATE,
    episode_count INT DEFAULT 0,
    plot_summary TEXT,
    poster_url VARCHAR(500),
    FOREIGN KEY (tv_show_id) REFERENCES tv_shows(id) ON DELETE CASCADE,
    UNIQUE KEY unique_show_season (tv_show_id, season_number),
    INDEX idx_tv_show (tv_show_id)
);

-- TV Episodes table
CREATE TABLE tv_episodes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tv_season_id INT NOT NULL,
    episode_number INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    air_date DATE,
    runtime_minutes INT,
    plot_summary TEXT,
    imdb_rating DECIMAL(3,1),
    imdb_votes INT,
    still_url VARCHAR(500),
    FOREIGN KEY (tv_season_id) REFERENCES tv_seasons(id) ON DELETE CASCADE,
    UNIQUE KEY unique_season_episode (tv_season_id, episode_number),
    INDEX idx_tv_season (tv_season_id),
    INDEX idx_air_date (air_date)
);

-- Movie-Genre relationships (many-to-many)
CREATE TABLE movie_genres (
    movie_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);

-- TV Show-Genre relationships (many-to-many)
CREATE TABLE tv_show_genres (
    tv_show_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (tv_show_id, genre_id),
    FOREIGN KEY (tv_show_id) REFERENCES tv_shows(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);

-- Movie cast and crew (many-to-many with role information)
CREATE TABLE movie_credits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    movie_id INT NOT NULL,
    person_id INT NOT NULL,
    role_type ENUM('cast', 'director', 'writer', 'producer', 'cinematographer', 'editor', 'composer') NOT NULL,
    character_name VARCHAR(255), -- For cast roles
    job_title VARCHAR(255), -- For crew roles
    credit_order INT, -- For ordering cast/crew
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
    INDEX idx_movie (movie_id),
    INDEX idx_person (person_id),
    INDEX idx_role_type (role_type)
);

-- TV Show cast and crew
CREATE TABLE tv_show_credits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tv_show_id INT NOT NULL,
    person_id INT NOT NULL,
    role_type ENUM('cast', 'creator', 'producer', 'writer', 'director') NOT NULL,
    character_name VARCHAR(255), -- For cast roles
    job_title VARCHAR(255), -- For crew roles
    credit_order INT,
    FOREIGN KEY (tv_show_id) REFERENCES tv_shows(id) ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
    INDEX idx_tv_show (tv_show_id),
    INDEX idx_person (person_id),
    INDEX idx_role_type (role_type)
);

-- Movie production companies
CREATE TABLE movie_production_companies (
    movie_id INT NOT NULL,
    company_id INT NOT NULL,
    PRIMARY KEY (movie_id, company_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES production_companies(id) ON DELETE CASCADE
);

-- TV Show production companies
CREATE TABLE tv_show_production_companies (
    tv_show_id INT NOT NULL,
    company_id INT NOT NULL,
    PRIMARY KEY (tv_show_id, company_id),
    FOREIGN KEY (tv_show_id) REFERENCES tv_shows(id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES production_companies(id) ON DELETE CASCADE
);

-- User ratings and reviews (optional feature)
CREATE TABLE user_reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    movie_id INT NULL,
    tv_show_id INT NULL,
    rating DECIMAL(3,1) CHECK (rating >= 0 AND rating <= 10),
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    helpful_votes INT DEFAULT 0,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (tv_show_id) REFERENCES tv_shows(id) ON DELETE CASCADE,
    CHECK ((movie_id IS NOT NULL AND tv_show_id IS NULL) OR (movie_id IS NULL AND tv_show_id IS NOT NULL)),
    INDEX idx_movie_reviews (movie_id),
    INDEX idx_tv_reviews (tv_show_id),
    INDEX idx_rating (rating)
);

-- Insert sample genres
INSERT INTO genres (name, description) VALUES
('Action', 'Fast-paced films with physical stunts and chases'),
('Adventure', 'Exciting journeys and quests'),
('Comedy', 'Humorous films designed to amuse'),
('Drama', 'Serious narratives focused on character development'),
('Horror', 'Films designed to frighten and create suspense'),
('Romance', 'Love stories and romantic relationships'),
('Sci-Fi', 'Science fiction with futuristic concepts'),
('Thriller', 'Suspenseful films with tension and excitement'),
('Fantasy', 'Magical and supernatural elements'),
('Crime', 'Stories involving criminal activity'),
('Mystery', 'Puzzles and unknown elements to be solved'),
('Animation', 'Animated films and shows'),
('Documentary', 'Non-fiction films'),
('Biography', 'Life stories of real people'),
('History', 'Historical events and periods'),
('War', 'Military conflicts and warfare'),
('Western', 'Stories set in the American Old West'),
('Musical', 'Films featuring songs and dance numbers'),
('Family', 'Suitable for all family members'),
('Sport', 'Athletic competitions and sports stories');

-- Insert sample production companies
INSERT INTO production_companies (name, country, founded_year, website) VALUES
('Marvel Studios', 'USA', 2005, 'https://www.marvel.com'),
('Warner Bros. Pictures', 'USA', 1923, 'https://www.warnerbros.com'),
('Universal Pictures', 'USA', 1912, 'https://www.universalpictures.com'),
('Paramount Pictures', 'USA', 1912, 'https://www.paramount.com'),
('Sony Pictures Entertainment', 'USA', 1987, 'https://www.sonypictures.com'),
('20th Century Studios', 'USA', 1935, 'https://www.20thcenturystudios.com'),
('Netflix', 'USA', 1997, 'https://www.netflix.com'),
('HBO', 'USA', 1972, 'https://www.hbo.com'),
('Disney', 'USA', 1923, 'https://www.disney.com'),
('A24', 'USA', 2012, 'https://a24films.com');

-- Insert sample people (actors, directors, writers)
INSERT INTO people (name, birth_date, biography) VALUES
('Robert Downey Jr.', '1965-04-04', 'American actor known for playing Tony Stark/Iron Man in the Marvel Cinematic Universe'),
('Scarlett Johansson', '1984-11-22', 'American actress known for her versatility in independent films and blockbusters'),
('Christopher Nolan', '1970-07-30', 'British-American filmmaker known for his complex narrative structures'),
('Quentin Tarantino', '1963-03-27', 'American film director known for his nonlinear storylines'),
('Meryl Streep', '1949-06-22', 'American actress with a record number of Academy Award nominations'),
('Leonardo DiCaprio', '1974-11-11', 'American actor and environmental activist'),
('Greta Gerwig', '1983-08-04', 'American actress, writer, and director'),
('Ryan Gosling', '1980-11-12', 'Canadian actor known for his roles in independent films and blockbusters'),
('Emma Stone', '1988-11-06', 'American actress known for her work in comedy and drama films'),
('Bryan Cranston', '1956-03-07', 'American actor best known for his role as Walter White in Breaking Bad'),
('Vince Gilligan', '1967-02-10', 'American writer and producer, creator of Breaking Bad'),
('Peter Dinklage', '1969-06-11', 'American actor known for his role as Tyrion Lannister in Game of Thrones'),
('Emilia Clarke', '1986-10-23', 'English actress known for playing Daenerys Targaryen in Game of Thrones'),
('David Benioff', '1970-09-25', 'American writer and producer, co-creator of Game of Thrones'),
('D.B. Weiss', '1971-04-23', 'American writer and producer, co-creator of Game of Thrones'),
('Marlon Brando', '1924-04-03', 'American actor widely considered one of the greatest and most influential actors of all time'),
('Al Pacino', '1940-04-25', 'American actor and filmmaker known for his intense method acting'),
('Francis Ford Coppola', '1939-04-07', 'American film director, producer, and screenwriter'),
('Liam Neeson', '1952-06-07', 'Northern Irish actor known for his work in biographical and historical films'),
('Ralph Fiennes', '1962-12-22', 'English actor known for his work in film and theatre'),
('Steven Spielberg', '1946-12-18', 'American filmmaker and one of the founding pioneers of the New Hollywood era'),
('Hayao Miyazaki', '1941-01-05', 'Japanese animator, director, producer, screenwriter, author, and manga artist'),
('Song Kang-ho', '1967-01-17', 'South Korean actor known for his work with director Bong Joon-ho'),
('Bong Joon-ho', '1969-09-14', 'South Korean film director and screenwriter known for genre-blending films'),
('Charlize Theron', '1975-08-07', 'South African and American actress and producer'),
('George Miller', '1945-03-03', 'Australian filmmaker best known for the Mad Max franchise'),
('Wes Anderson', '1969-05-01', 'American filmmaker known for his symmetrical framing and distinctive visual and narrative style'),
('Mahershala Ali', '1974-02-16', 'American actor known for his nuanced performances in independent films'),
('Barry Jenkins', '1979-11-19', 'American filmmaker known for his lyrical approach to storytelling'),
('Toni Collette', '1972-11-01', 'Australian actress known for her versatility in independent and mainstream films'),
('Ari Aster', '1986-07-15', 'American filmmaker known for his work in the horror genre'),
('Daniel Craig', '1968-03-02', 'English actor known for playing James Bond'),
('Rian Johnson', '1973-12-17', 'American filmmaker known for genre-bending films and television'),
('Michelle Yeoh', '1962-08-06', 'Malaysian actress known for her work in action films and dramatic roles'),
('Daniels', NULL, 'American filmmaking duo consisting of Daniel Kwan and Daniel Scheinert'),
('Cary Elwes', '1962-10-26', 'English actor known for his work in film and television'),
('Rob Reiner', '1947-03-06', 'American actor and filmmaker'),
('James Gandolfini', '1961-09-18', 'American actor best known for his role as Tony Soprano'),
('David Chase', '1945-08-22', 'American writer and producer, creator of The Sopranos'),
('Jennifer Aniston', '1969-02-11', 'American actress known for her role as Rachel Green on Friends'),
('David Crane', '1957-08-13', 'American writer and producer, co-creator of Friends'),
('Marta Kauffman', '1956-09-21', 'American writer and producer, co-creator of Friends'),
('Dominic West', '1969-10-15', 'English actor known for his role in The Wire'),
('David Simon', '1960-02-09', 'American writer and producer, creator of The Wire'),
('Jon Hamm', '1971-03-10', 'American actor known for his role as Don Draper in Mad Men'),
('Matthew Weiner', '1965-06-29', 'American writer and producer, creator of Mad Men'),
('Claire Foy', '1984-04-16', 'English actress known for playing Queen Elizabeth II in The Crown'),
('Peter Morgan', '1963-04-10', 'British screenwriter and playwright, creator of The Crown'),
('Benedict Cumberbatch', '1976-07-19', 'English actor known for playing Sherlock Holmes'),
('Martin Freeman', '1971-09-08', 'English actor known for playing Dr. Watson'),
('Mark Gatiss', '1966-10-17', 'English actor and writer, co-creator of Sherlock'),
('Steven Moffat', '1961-11-18', 'Scottish writer and producer, co-creator of Sherlock'),
('Zach Tyler Eisen', '1993-09-23', 'American voice actor who played Aang in Avatar: The Last Airbender'),
('Michael Dante DiMartino', '1974-07-18', 'American animation director, co-creator of Avatar: The Last Airbender'),
('Bryan Konietzko', '1975-06-01', 'American animation director, co-creator of Avatar: The Last Airbender'),
('Pedro Pascal', '1975-04-02', 'Chilean-American actor known for his role in The Mandalorian'),
('Jon Favreau', '1966-10-19', 'American actor and filmmaker, creator of The Mandalorian'),
('Jason Sudeikis', '1975-09-18', 'American actor and comedian known for playing Ted Lasso'),
('Bill Lawrence', '1968-12-26', 'American screenwriter and producer, co-creator of Ted Lasso'),
('Jeremy Allen White', '1991-02-17', 'American actor known for his role in The Bear'),
('Christopher Storer', NULL, 'American writer and director, creator of The Bear'),
('Lee Jung-jae', '1972-12-15', 'South Korean actor known for his role in Squid Game'),
('Hwang Dong-hyuk', '1971-05-26', 'South Korean filmmaker, creator of Squid Game');

-- Insert sample movies
INSERT INTO movies (title, original_title, release_date, runtime_minutes, plot_summary, tagline, imdb_rating, imdb_votes, status) VALUES
('Iron Man', 'Iron Man', '2008-05-02', 126, 'After being held captive in an Afghan cave, billionaire engineer Tony Stark creates a unique weaponized suit of armor to fight evil.', 'Heroes aren''t born. They''re built.', 7.9, 1000000, 'released'),
('The Dark Knight', 'The Dark Knight', '2008-07-18', 152, 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests.', 'Welcome to a world without rules.', 9.0, 2500000, 'released'),
('Pulp Fiction', 'Pulp Fiction', '1994-10-14', 154, 'The lives of two mob hitmen, a boxer, a gangster and his wife intertwine in four tales of violence and redemption.', 'Girls like me don''t make invitations like this to just anyone.', 8.9, 2000000, 'released'),
('La La Land', 'La La Land', '2016-12-09', 128, 'A jazz musician and an aspiring actress fall in love while pursuing their dreams in Los Angeles.', 'Here''s to the ones who dream.', 8.0, 550000, 'released'),
('Inception', 'Inception', '2010-07-16', 148, 'A thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea.', 'Your mind is the scene of the crime.', 8.8, 2300000, 'released'),
('The Godfather', 'The Godfather', '1972-03-24', 175, 'The patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.', 'An offer you can''t refuse.', 9.2, 1900000, 'released'),
('Schindler''s List', 'Schindler''s List', '1993-12-15', 195, 'In German-occupied Poland during World War II, industrialist Oskar Schindler gradually becomes concerned for his Jewish workforce after witnessing their persecution by the Nazis.', 'Whoever saves one life, saves the world entire.', 9.0, 1400000, 'released'),
('Spirited Away', '千と千尋の神隠し', '2001-07-20', 125, 'During her family''s move to the suburbs, a sullen 10-year-old girl wanders into a world ruled by gods, witches, and spirits.', 'The tunnel led Chihiro to a mysterious town.', 9.2, 800000, 'released'),
('Parasite', '기생충', '2019-05-30', 132, 'A poor family schemes to become employed by a wealthy family and infiltrate their household by posing as unrelated, highly qualified individuals.', 'Act like you own the place.', 8.5, 900000, 'released'),
('Mad Max: Fury Road', 'Mad Max: Fury Road', '2015-05-15', 120, 'In a post-apocalyptic wasteland, a woman rebels against a tyrannical ruler in search for her homeland with the aid of a group of female prisoners.', 'What a lovely day.', 8.1, 1000000, 'released'),
('The Grand Budapest Hotel', 'The Grand Budapest Hotel', '2014-03-28', 99, 'A writer encounters the owner of an aging high-class hotel, who tells him of his early years serving as a lobby boy in the hotel''s glorious years under an exceptional concierge.', 'A murder case of Madam D. with enormous wealth and the most outrageous events surrounding her sudden death!', 8.1, 850000, 'released'),
('Moonlight', 'Moonlight', '2016-10-21', 111, 'A young African-American man grapples with his identity and sexuality while experiencing the everyday struggles of childhood, adolescence, and burgeoning adulthood.', 'This is the story of a lifetime.', 7.4, 300000, 'released'),
('Hereditary', 'Hereditary', '2018-06-08', 127, 'A grieving family is haunted by tragedy and disturbing secrets.', 'Evil runs in the family.', 7.3, 350000, 'released'),
('Knives Out', 'Knives Out', '2019-11-27', 130, 'A detective investigates the death of a patriarch of an eccentric, combative family.', 'Everyone has a motive. No one has a clue.', 7.9, 650000, 'released'),
('Everything Everywhere All at Once', 'Everything Everywhere All at Once', '2022-03-25', 139, 'A Chinese-American woman gets swept up in an insane adventure, where she alone can save existence by exploring other universes connecting with the lives she could have lived.', 'The universe is so much bigger than you realize.', 7.8, 500000, 'released'),
('The Princess Bride', 'The Princess Bride', '1987-09-25', 98, 'A bedridden boy''s grandfather reads him the story of a farmboy-turned-pirate who encounters numerous obstacles, enemies and allies in his quest to be reunited with his true love.', 'True love, high adventure, great sword fights, and a giant!', 8.0, 450000, 'released');

-- Insert sample TV shows
INSERT INTO tv_shows (title, original_title, first_air_date, last_air_date, number_of_seasons, number_of_episodes, episode_runtime_minutes, plot_summary, imdb_rating, imdb_votes, status) VALUES
('Breaking Bad', 'Breaking Bad', '2008-01-20', '2013-09-29', 5, 62, 47, 'A chemistry teacher diagnosed with inoperable lung cancer turns to manufacturing and selling methamphetamine with a former student.', 9.5, 1800000, 'ended'),
('Game of Thrones', 'Game of Thrones', '2011-04-17', '2019-05-19', 8, 73, 57, 'Nine noble families fight for control over the lands of Westeros, while an ancient enemy returns.', 9.2, 2000000, 'ended'),
('Stranger Things', 'Stranger Things', '2016-07-15', NULL, 4, 42, 50, 'When a young boy vanishes, a small town uncovers a mystery involving secret experiments and supernatural forces.', 8.7, 1200000, 'ended'),
('The Office', 'The Office', '2005-03-24', '2013-05-16', 9, 201, 22, 'A mockumentary on a group of typical office workers, where the workday consists of ego clashes and inappropriate behavior.', 9.0, 650000, 'ended'),
('Better Call Saul', 'Better Call Saul', '2015-02-08', '2022-08-15', 6, 63, 46, 'The trials and tribulations of criminal lawyer Jimmy McGill in the years leading up to his fateful run-in with Walter White and Jesse Pinkman.', 8.9, 500000, 'ended'),
('The Sopranos', 'The Sopranos', '1999-01-10', '2007-06-10', 6, 86, 55, 'New Jersey mob boss Tony Soprano deals with personal and professional issues in his home and business life.', 9.2, 400000, 'ended'),
('Friends', 'Friends', '1994-09-22', '2004-05-06', 10, 236, 22, 'Follows the personal and professional lives of six twenty to thirty-something-year-old friends living in Manhattan.', 8.9, 1100000, 'ended'),
('The Wire', 'The Wire', '2002-06-02', '2008-03-09', 5, 60, 57, 'The Baltimore drug scene, as seen through the eyes of drug dealers and law enforcement.', 9.3, 350000, 'ended'),
('Mad Men', 'Mad Men', '2007-07-19', '2015-05-17', 7, 92, 47, 'A drama about one of New York''s most prestigious ad agencies at the beginning of the 1960s.', 8.7, 250000, 'ended'),
('The Crown', 'The Crown', '2016-11-04', '2023-12-14', 6, 60, 58, 'Follows the political rivalries and romance of Queen Elizabeth II''s reign and the events that shaped the second half of the twentieth century.', 8.6, 200000, 'ended'),
('Sherlock', 'Sherlock', '2010-07-25', '2017-01-15', 4, 13, 88, 'A modern update finds the famous sleuth and his doctor partner solving crime in 21st century London.', 9.1, 900000, 'ended'),
('Avatar: The Last Airbender', 'Avatar: The Last Airbender', '2005-02-21', '2008-07-19', 3, 61, 23, 'In a war-torn world of elemental magic, a young boy reawakens to undertake a dangerous mystic quest to fulfill his destiny as the Avatar.', 9.2, 350000, 'ended'),
('The Mandalorian', 'The Mandalorian', '2019-11-12', NULL, 3, 24, 40, 'The travels of a lone bounty hunter in the outer reaches of the galaxy, far from the authority of the New Republic.', 8.7, 600000, 'returning'),
('Ted Lasso', 'Ted Lasso', '2020-08-14', '2023-05-31', 3, 34, 30, 'American football coach Ted Lasso heads to London to manage AFC Richmond, a struggling English Premier League football team.', 8.8, 350000, 'ended'),
('The Bear', 'The Bear', '2022-06-23', NULL, 3, 28, 30, 'A young chef from the fine dining world comes home to Chicago to run his family sandwich shop.', 8.7, 200000, 'returning'),
('Squid Game', '오징어 게임', '2021-09-17', NULL, 2, 17, 54, 'Hundreds of cash-strapped players accept a strange invitation to compete in children''s games for a tempting prize.', 8.0, 650000, 'returning');

-- Link movies to genres
INSERT INTO movie_genres (movie_id, genre_id) VALUES
(1, 1), (1, 2), (1, 7), -- Iron Man: Action, Adventure, Sci-Fi
(2, 1), (2, 10), (2, 8), -- The Dark Knight: Action, Crime, Thriller
(3, 10), (3, 4), -- Pulp Fiction: Crime, Drama
(4, 6), (4, 18), (4, 4), -- La La Land: Romance, Musical, Drama
(5, 1), (5, 7), (5, 8), -- Inception: Action, Sci-Fi, Thriller
(6, 10), (6, 4), -- The Godfather: Crime, Drama
(7, 14), (7, 4), (7, 16), -- Schindler's List: Biography, Drama, War
(8, 12), (8, 2), (8, 19), -- Spirited Away: Animation, Adventure, Family
(9, 10), (9, 4), (9, 8), -- Parasite: Crime, Drama, Thriller
(10, 1), (10, 2), (10, 7), -- Mad Max: Fury Road: Action, Adventure, Sci-Fi
(11, 3), (11, 4), -- The Grand Budapest Hotel: Comedy, Drama
(12, 4), -- Moonlight: Drama
(13, 5), (13, 8), -- Hereditary: Horror, Thriller
(14, 10), (14, 3), (14, 11), -- Knives Out: Crime, Comedy, Mystery
(15, 1), (15, 2), (15, 7), -- Everything Everywhere All at Once: Action, Adventure, Sci-Fi
(16, 2), (16, 3), (16, 6); -- The Princess Bride: Adventure, Comedy, Romance

-- Link TV shows to genres
INSERT INTO tv_show_genres (tv_show_id, genre_id) VALUES
(1, 10), (1, 4), (1, 8), -- Breaking Bad: Crime, Drama, Thriller
(2, 1), (2, 2), (2, 4), (2, 9), -- Game of Thrones: Action, Adventure, Drama, Fantasy
(3, 4), (3, 9), (3, 5), (3, 7), -- Stranger Things: Drama, Fantasy, Horror, Sci-Fi
(4, 3), (4, 4), -- The Office: Comedy, Drama
(5, 10), (5, 4), -- Better Call Saul: Crime, Drama
(6, 10), (6, 4), -- The Sopranos: Crime, Drama
(7, 3), (7, 6), -- Friends: Comedy, Romance
(8, 10), (8, 4), -- The Wire: Crime, Drama
(9, 4), -- Mad Men: Drama
(10, 4), (10, 15), -- The Crown: Drama, History
(11, 10), (11, 4), (11, 11), -- Sherlock: Crime, Drama, Mystery
(12, 12), (12, 2), (12, 9), -- Avatar: The Last Airbender: Animation, Adventure, Fantasy
(13, 1), (13, 2), (13, 7), -- The Mandalorian: Action, Adventure, Sci-Fi
(14, 3), (14, 20), -- Ted Lasso: Comedy, Sport
(15, 3), (15, 4), -- The Bear: Comedy, Drama
(16, 1), (16, 4), (16, 8); -- Squid Game: Action, Drama, Thriller

-- Add movie credits (cast and crew)
INSERT INTO movie_credits (movie_id, person_id, role_type, character_name, credit_order) VALUES
(1, 1, 'cast', 'Tony Stark / Iron Man', 1), -- Robert Downey Jr. in Iron Man
(4, 7, 'director', NULL, 1), -- Greta Gerwig directed La La Land (fictional for this example)
(4, 8, 'cast', 'Sebastian', 1), -- Ryan Gosling in La La Land
(4, 9, 'cast', 'Mia', 2), -- Emma Stone in La La Land
(5, 3, 'director', NULL, 1), -- Christopher Nolan directed Inception
(5, 6, 'cast', 'Dom Cobb', 1), -- Leonardo DiCaprio in Inception
(3, 4, 'director', NULL, 1); -- Quentin Tarantino directed Pulp Fiction

-- Add TV show credits
INSERT INTO tv_show_credits (tv_show_id, person_id, role_type, character_name, credit_order) VALUES
(1, 10, 'cast', 'Walter White', 1), -- Bryan Cranston in Breaking Bad
(1, 11, 'creator', NULL, 1), -- Vince Gilligan created Breaking Bad
(2, 12, 'cast', 'Tyrion Lannister', 1), -- Peter Dinklage in Game of Thrones
(2, 13, 'cast', 'Daenerys Targaryen', 2), -- Emilia Clarke in Game of Thrones
(2, 14, 'creator', NULL, 1), -- David Benioff co-created Game of Thrones
(2, 15, 'creator', NULL, 2); -- D.B. Weiss co-created Game of Thrones

-- Link movies to production companies
INSERT INTO movie_production_companies (movie_id, company_id) VALUES
(1, 1), -- Iron Man - Marvel Studios
(2, 2), -- The Dark Knight - Warner Bros. Pictures
(3, 1), -- Pulp Fiction - Marvel Studios (fictional for this example)
(4, 9), -- La La Land - Disney
(5, 3), -- Inception - Universal Pictures
(6, 4), -- The Godfather - Paramount Pictures
(7, 3), -- Schindler's List - Universal Pictures
(8, 9), -- Spirited Away - Disney
(9, 7), -- Parasite - Netflix (fictional for this example)
(10, 2), -- Mad Max: Fury Road - Warner Bros. Pictures
(11, 2), -- The Grand Budapest Hotel - Warner Bros. Pictures (fictional for this example)
(12, 10), -- Moonlight - A24
(13, 10), -- Hereditary - A24
(14, 5), -- Knives Out - Sony Pictures Entertainment
(15, 10), -- Everything Everywhere All at Once - A24
(16, 5); -- The Princess Bride - Sony Pictures Entertainment (fictional for this example)

-- Link TV shows to production companies
INSERT INTO tv_show_production_companies (tv_show_id, company_id) VALUES
(1, 5), -- Breaking Bad - Sony Pictures Entertainment
(2, 8), -- Game of Thrones - HBO
(3, 7), -- Stranger Things - Netflix
(4, 3), -- The Office - Universal Pictures (fictional for this example)
(5, 5), -- Better Call Saul - Sony Pictures Entertainment
(6, 8), -- The Sopranos - HBO
(7, 2), -- Friends - Warner Bros. Pictures
(8, 8), -- The Wire - HBO
(9, 1), -- Mad Men - Marvel Studios (fictional for this example)
(10, 7), -- The Crown - Netflix
(11, 2), -- Sherlock - Warner Bros. Pictures (fictional for this example)
(12, 7), -- Avatar: The Last Airbender - Netflix (fictional for this example)
(13, 9), -- The Mandalorian - Disney
(14, 1), -- Ted Lasso - Marvel Studios (fictional for this example)
(15, 7), -- The Bear - Netflix (fictional for this example)
(16, 7); -- Squid Game - Netflix

-- Add sample seasons for Breaking Bad
INSERT INTO tv_seasons (tv_show_id, season_number, name, air_date, episode_count) VALUES
(1, 1, 'Season 1', '2008-01-20', 7),
(1, 2, 'Season 2', '2009-03-08', 13),
(1, 3, 'Season 3', '2010-03-21', 13),
(1, 4, 'Season 4', '2011-07-17', 13),
(1, 5, 'Season 5', '2012-07-15', 16);

-- Add sample seasons for Game of Thrones
INSERT INTO tv_seasons (tv_show_id, season_number, name, air_date, episode_count) VALUES
(2, 1, 'Season 1', '2011-04-17', 10),
(2, 2, 'Season 2', '2012-04-01', 10),
(2, 3, 'Season 3', '2013-03-31', 10),
(2, 4, 'Season 4', '2014-04-06', 10),
(2, 5, 'Season 5', '2015-04-12', 10);

-- Add sample seasons for The Office
INSERT INTO tv_seasons (tv_show_id, season_number, name, air_date, episode_count) VALUES
(4, 1, 'Season 1', '2005-03-24', 6),
(4, 2, 'Season 2', '2005-09-20', 22),
(4, 3, 'Season 3', '2006-09-21', 25),
(4, 4, 'Season 4', '2007-09-27', 19),
(4, 5, 'Season 5', '2008-09-25', 28);

-- Add sample seasons for Friends
INSERT INTO tv_seasons (tv_show_id, season_number, name, air_date, episode_count) VALUES
(7, 1, 'Season 1', '1994-09-22', 24),
(7, 2, 'Season 2', '1995-09-21', 24),
(7, 3, 'Season 3', '1996-09-19', 25),
(7, 4, 'Season 4', '1997-09-25', 24),
(7, 5, 'Season 5', '1998-09-24', 24);

-- Add sample episodes for Breaking Bad Season 1
INSERT INTO tv_episodes (tv_season_id, episode_number, title, air_date, runtime_minutes, plot_summary, imdb_rating) VALUES
(1, 1, 'Pilot', '2008-01-20', 58, 'Walter White, a struggling high school chemistry teacher, is diagnosed with advanced lung cancer. He turns to a life of crime, producing and selling methamphetamine with his former student Jesse Pinkman.', 9.0),
(1, 2, 'Cat''s in the Bag...', '2008-01-27', 48, 'Walter and Jesse attempt to tie up loose ends. The desperate situation gets more complicated with the flip of a coin.', 8.2),
(1, 3, '...And the Bag''s in the River', '2008-02-10', 48, 'Walter fights for his life. Jesse realizes they must dispose of their problem differently than they thought.', 8.3),
(1, 4, 'Cancer Man', '2008-02-17', 48, 'Walter tells the rest of his family about his cancer. Jesse tries to make amends with his parents.', 8.1),
(1, 5, 'Gray Matter', '2008-02-24', 48, 'Walter and Skyler attend Elliott and Gretchen''s party. Jesse goes to see his parents.', 8.3),
(1, 6, 'Crazy Handful of Nothin''', '2008-03-02', 48, 'Walter adopts a new persona to take care of business. Jesse finds himself in hot water.', 8.8),
(1, 7, 'A No-Rough-Stuff-Type Deal', '2008-03-09', 48, 'Walter and Jesse find themselves in trouble with their suppliers. Skyler starts to worry about Walter.', 8.2);

-- Add sample episodes for Game of Thrones Season 1
INSERT INTO tv_episodes (tv_season_id, episode_number, title, air_date, runtime_minutes, plot_summary, imdb_rating) VALUES
(6, 1, 'Winter Is Coming', '2011-04-17', 62, 'Lord Stark is torn between his family and an old friend when asked to serve at the side of King Robert Baratheon.', 9.0),
(6, 2, 'The Kingsroad', '2011-04-24', 56, 'While Bran recovers from his fall, Ned takes only his daughters to King''s Landing. Jon Snow goes with his uncle Benjen to the Wall.', 8.8),
(6, 3, 'Lord Snow', '2011-05-01', 58, 'Lord Stark and his daughters arrive at King''s Landing to discover the intrigues of the king''s realm.', 8.7),
(6, 4, 'Cripples, Bastards, and Broken Things', '2011-05-08', 56, 'Eddard investigates Jon Arryn''s murder. Jon befriends Samwell Tarly, a coward who has come to join the Night''s Watch.', 8.8),
(6, 5, 'The Wolf and the Lion', '2011-05-15', 55, 'Catelyn has captured Tyrion and plans to bring him to her sister, Lysa Arryn, at the Vale, to be tried for his supposed crimes.', 9.1);

-- Add sample episodes for The Office Season 1
INSERT INTO tv_episodes (tv_season_id, episode_number, title, air_date, runtime_minutes, plot_summary, imdb_rating) VALUES
(11, 1, 'Pilot', '2005-03-24', 22, 'A documentary crew arrives at the Scranton branch of the Dunder Mifflin Paper Company to observe the employees.', 7.5),
(11, 2, 'Diversity Day', '2005-03-29', 22, 'Michael''s inappropriate behavior prompts corporate to send him to diversity training, which he decides to extend to the rest of the office.', 8.3),
(11, 3, 'Health Care', '2005-04-05', 22, 'Michael leaves Jim in charge of picking the new health care plan for the employees.', 7.9),
(11, 4, 'The Alliance', '2005-04-12', 22, 'Jim and Dwight work together to uncover an alliance forming in the office.', 8.0),
(11, 5, 'Basketball', '2005-04-19', 22, 'Michael and his staff challenge the warehouse workers to a basketball game with the promise of getting to leave work early.', 8.4),
(11, 6, 'Hot Girl', '2005-04-26', 22, 'Everyone in the office is smitten with the attractive purse saleswoman who visits the office.', 7.8);

-- Add sample episodes for Friends Season 1
INSERT INTO tv_episodes (tv_season_id, episode_number, title, air_date, runtime_minutes, plot_summary, imdb_rating) VALUES
(16, 1, 'The Pilot', '1994-09-22', 22, 'Rachel leaves her fiancé at the altar and moves in with her old friend Monica. Meanwhile, Monica goes on a date with Paul the wine guy.', 8.3),
(16, 2, 'The One with the Sonogram at the End', '1994-09-29', 22, 'Ross discovers that his ex-wife is pregnant with his child, and he has to attend the sonogram along with her lesbian partner.', 8.1),
(16, 3, 'The One with the Thumb', '1994-10-06', 22, 'Monica becomes irritated when everyone likes her new boyfriend more than she does. Chandler starts smoking again.', 8.2),
(16, 4, 'The One with George Stephanopoulos', '1994-10-13', 22, 'The girls spy on George Stephanopoulos. Ross has a bad day when Carol and Susan show up at the hospital.', 8.1),
(16, 5, 'The One with the East German Laundry Detergent', '1994-10-20', 22, 'Rachel does her laundry for the first time with Ross''s help. Monica goes on a date with a guy from her high school.', 8.3);

-- Add sample user reviews
INSERT INTO user_reviews (user_name, email, movie_id, rating, review_text) VALUES
('MovieLover123', 'movielover@email.com', 1, 8.5, 'Great start to the MCU! Robert Downey Jr. is perfect as Tony Stark.'),
('CinemaFan', 'cinemafan@email.com', 2, 10.0, 'Christopher Nolan''s masterpiece. Heath Ledger''s Joker is unforgettable.'),
('FilmCritic', 'critic@email.com', 4, 7.5, 'Beautiful cinematography and great music, but the story felt a bit predictable.'),
('ClassicMovieFan', 'classic@email.com', 6, 9.8, 'The Godfather is cinema at its finest. Brando''s performance is legendary.'),
('HistoryBuff', 'history@email.com', 7, 9.5, 'Schindler''s List is a powerful and important film that everyone should see.'),
('AnimationLover', 'anime@email.com', 8, 9.0, 'Spirited Away is a masterpiece of animation and storytelling from Miyazaki.'),
('IndieFilmFan', 'indie@email.com', 9, 8.8, 'Parasite is a brilliant social commentary wrapped in a thrilling story.'),
('ActionJunkie', 'action@email.com', 10, 8.2, 'Mad Max: Fury Road is pure adrenaline from start to finish. Incredible practical effects.'),
('ComedyLover', 'comedy@email.com', 16, 8.5, 'The Princess Bride is the perfect blend of adventure, comedy, and romance. Inconceivable!'),
('HorrorFan', 'horror@email.com', 13, 7.8, 'Hereditary is genuinely terrifying. Toni Collette gives an incredible performance.'),
('MysteryReader', 'mystery@email.com', 14, 8.1, 'Knives Out is a clever whodunit with great performances and witty dialogue.'),
('SciFiEnthusiast', 'scifi@email.com', 15, 8.0, 'Everything Everywhere All at Once is a wild, creative ride that somehow all comes together.');

INSERT INTO user_reviews (user_name, email, tv_show_id, rating, review_text) VALUES
('TVAddict', 'tvfan@email.com', 1, 9.5, 'One of the greatest TV shows ever made. Bryan Cranston''s performance is phenomenal.'),
('SeriesFan', 'seriesfan@email.com', 2, 8.0, 'Epic fantasy series with amazing production value, though the ending was controversial.'),
('CrimeDramaFan', 'crime@email.com', 6, 9.2, 'The Sopranos changed television forever. James Gandolfini was perfect as Tony.'),
('SitcomLover', 'sitcom@email.com', 7, 8.8, 'Friends never gets old. The chemistry between the cast is amazing.'),
('DetectiveFan', 'detective@email.com', 8, 9.1, 'The Wire is the most realistic portrayal of urban life on television.'),
('PeriodDramaFan', 'period@email.com', 9, 8.4, 'Mad Men perfectly captures the 1960s advertising world and social changes.'),
('BritishTVFan', 'british@email.com', 11, 9.3, 'Sherlock brilliantly updates the classic detective for modern times.'),
('AnimationFan', 'animation@email.com', 12, 9.4, 'Avatar: The Last Airbender is a masterclass in storytelling and character development.'),
('StarWarsFan', 'starwars@email.com', 13, 8.6, 'The Mandalorian brought back the magic of Star Wars with great characters and stories.'),
('ComedyFan', 'comedy@email.com', 14, 8.9, 'Ted Lasso is heartwarming and hilarious. Jason Sudeikis is perfect in the role.'),
('FoodieFan', 'foodie@email.com', 15, 8.5, 'The Bear perfectly captures the chaos and intensity of restaurant life.'),
('ThrillerFan', 'thriller@email.com', 16, 7.9, 'Squid Game is a gripping social commentary disguised as a survival thriller.');

-- Create some useful views for common queries
CREATE VIEW movie_details_with_ratings AS
SELECT 
    m.id,
    m.title,
    m.release_date,
    m.runtime_minutes,
    m.imdb_rating,
    m.imdb_votes,
    GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') as genres,
    GROUP_CONCAT(DISTINCT CASE WHEN mc.role_type = 'director' THEN p.name END SEPARATOR ', ') as directors,
    GROUP_CONCAT(DISTINCT CASE WHEN mc.role_type = 'cast' THEN CONCAT(p.name, ' as ', mc.character_name) END ORDER BY mc.credit_order SEPARATOR ', ') as cast_members
FROM movies m
LEFT JOIN movie_genres mg ON m.id = mg.movie_id
LEFT JOIN genres g ON mg.genre_id = g.id
LEFT JOIN movie_credits mc ON m.id = mc.movie_id
LEFT JOIN people p ON mc.person_id = p.id
GROUP BY m.id, m.title, m.release_date, m.runtime_minutes, m.imdb_rating, m.imdb_votes;

CREATE VIEW tv_show_details_with_ratings AS
SELECT 
    t.id,
    t.title,
    t.first_air_date,
    t.last_air_date,
    t.number_of_seasons,
    t.number_of_episodes,
    t.imdb_rating,
    t.imdb_votes,
    t.status,
    GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') as genres,
    GROUP_CONCAT(DISTINCT CASE WHEN tc.role_type = 'creator' THEN p.name END SEPARATOR ', ') as creators,
    GROUP_CONCAT(DISTINCT CASE WHEN tc.role_type = 'cast' THEN CONCAT(p.name, ' as ', tc.character_name) END ORDER BY tc.credit_order SEPARATOR ', ') as cast_members
FROM tv_shows t
LEFT JOIN tv_show_genres tg ON t.id = tg.tv_show_id
LEFT JOIN genres g ON tg.genre_id = g.id
LEFT JOIN tv_show_credits tc ON t.id = tc.tv_show_id
LEFT JOIN people p ON tc.person_id = p.id
GROUP BY t.id, t.title, t.first_air_date, t.last_air_date, t.number_of_seasons, t.number_of_episodes, t.imdb_rating, t.imdb_votes, t.status;

-- Show completion message
SELECT 'Database initialization completed successfully!' as message;