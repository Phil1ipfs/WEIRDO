-- Add new notification types to the enum
ALTER TYPE enum_notifications_type ADD VALUE IF NOT EXISTS 'event_registration';
ALTER TYPE enum_notifications_type ADD VALUE IF NOT EXISTS 'event_cancellation';
