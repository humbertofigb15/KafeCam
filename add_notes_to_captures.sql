-- Add notes column to captures table
ALTER TABLE public.captures 
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.captures.notes IS 'User notes about the capture';
