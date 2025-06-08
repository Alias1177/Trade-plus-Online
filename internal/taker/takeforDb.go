package taker

import (
	"Strategy/config"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/smtp"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

type Handler struct {
	cfg  *config.Config
	sqlx *sqlx.DB
}

type RequestData struct {
	Number     string `json:"number"`
	Email      string `json:"email"`
	TGNikName  string `json:"TGNikName"`
	SelectedId string `json:"selected_id"` // Выбранный ID
}

type DatabaseRecord struct {
	Number    string `json:"number" db:"number"`
	Email     string `json:"email" db:"email"`
	TGNikName string `json:"tg_nickname" db:"tgnikname"`
	Id1       string `json:"id1" db:"id1"`
	Id2       string `json:"id2" db:"id2"`
	Id3       string `json:"id3" db:"id3"`
}

func New(cfg *config.Config, db *sqlx.DB) *Handler {
	return &Handler{
		cfg:  cfg,
		sqlx: db,
	}
}

// Загрузка HTML из файла
func loadHTML(filename string) (string, error) {
	content, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", err
	}
	return string(content), nil
}

// Отправка HTML email через Mail.ru с TLS
func (h *Handler) sendEmail(to, subject, body string) error {
	from := h.cfg.EmailAddress
	password := h.cfg.EmailPassword
	smtpHost := h.cfg.SmtpHost
	smtpPort := h.cfg.SmtpPort

	log.Printf("🔧 Email config - From: %s, To: %s, SMTP: %s:%s", from, to, smtpHost, smtpPort)

	msg := fmt.Sprintf("From: %s\nTo: %s\nSubject: %s\nContent-Type: text/html; charset=UTF-8\n\n%s",
		from, to, subject, body)

	auth := smtp.PlainAuth("", from, password, smtpHost)

	// Настройка TLS для Mail.ru
	tlsconfig := &tls.Config{
		InsecureSkipVerify: false,
		ServerName:         smtpHost,
	}

	// Для Mail.ru используем правильный порт и подключение
	if smtpPort == "465" {
		log.Printf("📧 Using SSL/TLS connection on port 465")
		// SSL/TLS подключение для порта 465
		conn, err := tls.Dial("tcp", smtpHost+":"+smtpPort, tlsconfig)
		if err != nil {
			return fmt.Errorf("failed to connect to SMTP server: %w", err)
		}
		defer conn.Close()

		client, err := smtp.NewClient(conn, smtpHost)
		if err != nil {
			return fmt.Errorf("failed to create SMTP client: %w", err)
		}
		defer client.Quit()

		if err = client.Auth(auth); err != nil {
			return fmt.Errorf("SMTP authentication failed: %w", err)
		}

		if err = client.Mail(from); err != nil {
			return fmt.Errorf("failed to set sender: %w", err)
		}

		if err = client.Rcpt(to); err != nil {
			return fmt.Errorf("failed to set recipient: %w", err)
		}

		writer, err := client.Data()
		if err != nil {
			return fmt.Errorf("failed to get data writer: %w", err)
		}
		defer writer.Close()

		_, err = writer.Write([]byte(msg))
		if err != nil {
			return fmt.Errorf("failed to write message: %w", err)
		}

		log.Printf("✅ Email sent successfully via SSL/TLS")
		return nil
	} else {
		log.Printf("📧 Using STARTTLS connection on port %s", smtpPort)
		// STARTTLS для порта 587
		err := smtp.SendMail(smtpHost+":"+smtpPort, auth, from, []string{to}, []byte(msg))
		if err != nil {
			return fmt.Errorf("failed to send email via STARTTLS: %w", err)
		}

		log.Printf("✅ Email sent successfully via STARTTLS")
		return nil
	}
}

func (h *Handler) InsertIntoDb(w http.ResponseWriter, r *http.Request) {
	var data RequestData

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		log.Printf("Error decoding JSON: %v", err)
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Базовая валидация данных
	if data.Email == "" {
		http.Error(w, "Email is required", http.StatusBadRequest)
		return
	}
	if data.Number == "" {
		http.Error(w, "Phone number is required", http.StatusBadRequest)
		return
	}
	if data.SelectedId == "" {
		http.Error(w, "Package selection is required", http.StatusBadRequest)
		return
	}

	// Проверяем дубликат email
	var existingEmail string
	err := h.sqlx.Get(&existingEmail, "SELECT email FROM send WHERE LOWER(email) = LOWER($1) LIMIT 1", data.Email)
	if err == nil {
		// Email уже существует
		log.Printf("Duplicate email attempt: %s", data.Email)
		http.Error(w, "This email has already been registered for early bird offer", http.StatusConflict)
		return
	}

	// Проверяем дубликат номера телефона
	var existingNumber string
	err = h.sqlx.Get(&existingNumber, "SELECT number FROM send WHERE number = $1 LIMIT 1", data.Number)
	if err == nil {
		// Номер уже существует
		log.Printf("Duplicate phone number attempt: %s", data.Number)
		http.Error(w, "This phone number has already been registered for early bird offer", http.StatusConflict)
		return
	}

	// Определяем значения для полей Id1, Id2, Id3 на основе выбранного ID
	id1Value := ""
	id2Value := ""
	id3Value := ""

	// Заполняем только выбранное поле
	switch data.SelectedId {
	case "Id1":
		id1Value = "selected"
	case "Id2":
		id2Value = "selected"
	case "Id3":
		id3Value = "selected"
	default:
		http.Error(w, "Invalid package selection", http.StatusBadRequest)
		return
	}

	_, err = h.sqlx.Exec("INSERT INTO send (number, email, tgnikname, id1, id2, id3) VALUES($1, $2, $3, $4, $5, $6)",
		data.Number, data.Email, data.TGNikName, id1Value, id2Value, id3Value)
	if err != nil {
		log.Printf("Database error: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	log.Printf("✅ New registration: %s - %s - %s", data.Email, data.Number, data.SelectedId)

	// Отправляем HTML из файла
	go func() {
		log.Printf("🔄 Начинаю отправку email для %s", data.Email)

		htmlBody, err := loadHTML("latter.html")
		if err != nil {
			log.Printf("❌ Ошибка загрузки HTML: %v", err)
			log.Printf("📁 Проверьте наличие файла latter.html в рабочей директории")
			return
		}

		log.Printf("✅ HTML загружен успешно, размер: %d символов", len(htmlBody))
		log.Printf("📧 Настройки SMTP: %s:%s", h.cfg.SmtpHost, h.cfg.SmtpPort)
		log.Printf("📧 От: %s, К: %s", h.cfg.EmailAddress, data.Email)

		err = h.sendEmail(data.Email, "Уведомление", htmlBody)
		if err != nil {
			log.Printf("❌ Ошибка отправки email: %v", err)
		} else {
			log.Printf("✅ Email успешно отправлен на %s", data.Email)
		}
	}()

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Data saved"))
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	if _, err := w.Write([]byte("здоров")); err != nil {
		log.Println(err, "Не здоров")
	}
}

func (h *Handler) GetAllRecords(w http.ResponseWriter, r *http.Request) {
	var records []DatabaseRecord

	err := h.sqlx.Select(&records, "SELECT number, email, tgnikname, id1, id2, id3 FROM send ORDER BY email")
	if err != nil {
		log.Printf("Database error getting records: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	// Устанавливаем заголовки для JSON
	w.Header().Set("Content-Type", "application/json")

	// Возвращаем JSON
	if err := json.NewEncoder(w).Encode(records); err != nil {
		log.Printf("JSON encoding error: %v", err)
		http.Error(w, "JSON encoding error", http.StatusInternalServerError)
		return
	}

	log.Printf("📊 Records retrieved: %d entries", len(records))
}

func Connect(cfg *config.Config) *sqlx.DB {
	// Пытаемся подключиться с повторными попытками
	maxRetries := 10
	retryInterval := 5 // секунд

	for attempt := 1; attempt <= maxRetries; attempt++ {
		log.Printf("🔄 Database connection attempt %d/%d...", attempt, maxRetries)

		conn, err := sqlx.Connect("postgres", cfg.DbConnectionString)
		if err != nil {
			log.Printf("❌ Connection attempt %d failed: %v", attempt, err)
			if attempt == maxRetries {
				log.Fatal("❌ Failed to connect to database after all attempts")
			}
			log.Printf("⏳ Retrying in %d seconds...", retryInterval)
			time.Sleep(time.Duration(retryInterval) * time.Second)
			continue
		}

		// Проверяем что соединение работает
		if err = conn.Ping(); err != nil {
			log.Printf("❌ Ping attempt %d failed: %v", attempt, err)
			conn.Close()
			if attempt == maxRetries {
				log.Fatal("❌ Failed to ping database after all attempts")
			}
			log.Printf("⏳ Retrying in %d seconds...", retryInterval)
			time.Sleep(time.Duration(retryInterval) * time.Second)
			continue
		}

		log.Printf("✅ Database connected successfully on attempt %d", attempt)
		return conn
	}

	// Этот код никогда не должен выполниться, но Go требует return
	log.Fatal("❌ Unexpected error in database connection logic")
	return nil
}

func (h *Handler) Close() error {
	if err := h.sqlx.Close(); err != nil {
		log.Println(err)
		return fmt.Errorf("error close db")
	}
	return nil
}
