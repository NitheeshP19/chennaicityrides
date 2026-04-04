import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const { trip_id, driver_name, driver_phone, vehicle_type, price } =
      await req.json();

    if (!trip_id) {
      return new Response(JSON.stringify({ error: "Missing trip_id" }), {
        status: 400,
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { error } = await supabase
      .from("trip_requests")
      .update({
        driver_name,
        driver_phone,
        vehicle_type,
        price,
        status: "pending_payment",
        quoted_at: new Date().toISOString(),
      })
      .eq("id", trip_id);

    if (error) {
      return new Response(JSON.stringify({ error }), { status: 400 });
    }

    return new Response(
      JSON.stringify({ success: true, message: "Trip allotted successfully" }),
      { status: 200 }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
    });
  }
});
