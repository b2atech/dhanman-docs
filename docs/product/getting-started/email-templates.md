# 📧 Email & Template Service - CrossCuttingConcern Documentation

## Overview
This module provides a centralized and reusable email sending solution using:
- `EmailService` for sending emails via SMTP
- `EmailTemplateService` for managing DB-driven email templates
- `TemplatedEmailService` as a helper that combines both

This design keeps the configuration and transport details abstracted from consumers.

---

## 📦 Folder Structure

```
CrossCuttingConcern.Email/
├── Abstractions/
│   ├── IEmailService.cs
│   └── IEmailTemplateService.cs
│
├── Entities/
│   ├── EmailMessage.cs
│   └── ProcessedEmailTemplate.cs
│
├── Services/
│   ├── EmailService.cs
│   ├── EmailTemplateService.cs
│   └── TemplatedEmailService.cs
│
├── Settings/
│   └── SmtpSettings.cs
```

---

## 🔧 Configuration

### `appsettings.json`
```json
"Smtp": {
  "Host": "smtp-relay.brevo.com",
  "Port": 587,
  "Username": "your-smtp-user",
  "Password": "your-smtp-password",
  "FromEmail": "support@dhanman.com"
}
```

### Connection String
```json
"ConnectionStrings": {
  "TemplateDb": "Host=localhost;Port=5432;Database=TemplateDb;Username=postgres;Password=password"
}
```

### DI Registration
```csharp
services.Configure<SmtpSettings>(configuration.GetSection("Smtp"));
services.AddSingleton<IDateTime, SystemDateTime>();

services.AddDbContext<TemplateDbContext>(options =>
    options.UseNpgsql(configuration.GetConnectionString("TemplateDb")));

services.AddScoped<ITemplateDbContext>(provider =>
    provider.GetRequiredService<TemplateDbContext>());

services.AddScoped<IEmailService, EmailService>();
services.AddScoped<IEmailTemplateService, EmailTemplateService>();
services.AddScoped<TemplatedEmailService>();
```

---

## ✉️ EmailService
### Usage
```csharp
await _emailService.SendEmailAsync(
    to: "bharat.mane@gmail.com",
    subject: "Manual Email",
    body: "<p>Hello Bharat</p>",
    isHtml: true);
```

---

## 🧩 EmailTemplateService
### Description
Fetches email templates from DB, caches them, and replaces placeholders.

### Example Template in DB
```
Subject: Welcome to Dhanman
BodyHtml: Hello {{CustomerName}}, click <a href="{{LoginUrl}}">here</a> to login.
```

### Usage
```csharp
var placeholders = new Dictionary<string, string>
{
    ["CustomerName"] = "Bharat",
    ["LoginUrl"] = "https://dhanman.com/login"
};

var template = await _templateService.GetProcessedTemplateAsync(101, placeholders);
```

---

## 🤖 TemplatedEmailService (Helper)
### Usage
```csharp
var placeholders = new Dictionary<string, string>
{
    ["CustomerName"] = order.CustomerName,
    ["OrderId"] = order.Id.ToString()
};

await _templatedEmailService.SendAsync(
    templateId: 102,
    recipient: order.CustomerEmail,
    placeholders: placeholders);
```

No need to manually deal with template loading or SMTP.

---

## 🧪 Consumer Example (Service Layer)
```csharp
public class OrderService
{
    private readonly TemplatedEmailService _templatedEmailService;

    public OrderService(TemplatedEmailService templatedEmailService)
    {
        _templatedEmailService = templatedEmailService;
    }

    public async Task SendOrderConfirmation(Order order)
    {
        var placeholders = new Dictionary<string, string>
        {
            ["CustomerName"] = order.CustomerName,
            ["OrderId"] = order.Id.ToString()
        };

        await _templatedEmailService.SendAsync(102, order.CustomerEmail, placeholders);
    }
}
```

---

## 🧠 Notes
- `TemplatedEmailService` is a **concrete helper**, injected directly.
- `EmailTemplateService` uses `TemplateDbContext` with scoped lifetime.
- SMTP settings are injected via `IOptions<SmtpSettings>`.
- Placeholders must exactly match what the template expects (e.g. `{{CustomerName}}`).

---

## ✅ Summary
With this module, any service can send emails via a template-driven system without worrying about HTML formatting or SMTP details.

Use `TemplatedEmailService` to send branded, consistent emails with ease.
