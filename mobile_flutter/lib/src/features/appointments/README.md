# Appointments Feature

This feature allows patients to manage their medical appointments within the NCD App.

## Features

- View a list of scheduled, completed, and cancelled appointments
- Add new appointments with details such as doctor, location, and date/time
- Edit existing appointments
- Update appointment status
- Delete appointments

## Setup Instructions

### 1. Database Setup

Run the SQL script in `sql/create_appointments_table.sql` in your Supabase SQL Editor to create the necessary table with appropriate Row Level Security policies.

### 2. Mobile App

The Appointments feature is implemented with the following components:

- `appointment.dart` - Data model for appointments
- `appointment_service.dart` - Service for CRUD operations with Supabase
- `appointment_page.dart` - Main page for displaying and managing appointments
- `appointment_form.dart` - Form for adding/editing appointments
- `appointment_list.dart` - List widget for displaying appointments

### 3. Accessing the Feature

The Appointments feature can be accessed via the `/appointments` route or through the main navigation menu.

## Usage

### Adding an Appointment

1. Tap the "Add Appointment" button
2. Fill out the appointment details:
   - Title (required)
   - Date and time
   - Doctor name (optional)
   - Location (optional)
   - Description (required)
3. Tap "Add Appointment" to save

### Editing an Appointment

1. Tap on an appointment card or the edit icon
2. Modify the details
3. Tap "Update Appointment" to save changes

### Changing Appointment Status

1. Tap the "Status" button on an appointment card
2. Select the new status (Scheduled, Completed, Cancelled)

### Deleting an Appointment

1. Tap the delete icon on an appointment card
2. Confirm deletion when prompted