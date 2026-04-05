import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.2/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: any) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { 
      headers: {
        ...corsHeaders,
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
        'Access-Control-Allow-Headers': '*'
      } 
    });
  }

  try {
    const defaultHeaders = {
      ...corsHeaders,
      'Access-Control-Allow-Origin': '*',
      "Content-Type": "application/json"
    };

    let reqBodyStr = await req.text();
    if (!reqBodyStr) {
        return new Response(JSON.stringify({ error: "Empty request body" }), {
            status: 400,
            headers: defaultHeaders
        });
    }
    
    // Parse the JSON reliably
    const { trip_id, driver_name, driver_phone, vehicle_type, price } = JSON.parse(reqBodyStr);

    if (!trip_id) {
      return new Response(JSON.stringify({ error: "Missing trip_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // 1. Update the trip request
    const { data: tripData, error: updateError } = await supabase
      .from("trip_requests")
      .update({
        driver_name,
        driver_phone,
        vehicle_type,
        price,
        status: "pending_payment",
        quoted_at: new Date().toISOString(),
      })
      .eq("id", trip_id)
      .select("user_id")
      .single();

    if (updateError || !tripData) {
      return new Response(JSON.stringify({ error: updateError }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Fetch the user's FCM token
    const { data: tokenData } = await supabase
      .from("user_fcm_tokens")
      .select("fcm_token")
      .eq("user_id", tripData.user_id)
      .single();

    // 3. Send the push notification via FCM V1 API
    if (tokenData?.fcm_token) {
      try {
        const envVar = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
        if (envVar) {
          const serviceAccount = JSON.parse(envVar);
          
          // Fix: PEM to DER conversion for the JWT library
          const pemContent = serviceAccount.private_key
            .replace(/\\n/g, "\n")
            .replace("-----BEGIN PRIVATE KEY-----", "")
            .replace("-----END PRIVATE KEY-----", "")
            .trim();
          const binaryString = atob(pemContent.replace(/\s/g, ""));
          const bytes = new Uint8Array(binaryString.length);
          for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
          }

          const key = await crypto.subtle.importKey(
            "pkcs8",
            bytes.buffer,
            { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
            false,
            ["sign"]
          );

          const jwt = await create(
            { alg: "RS256", typ: "JWT" },
            {
              iss: serviceAccount.client_email,
              sub: serviceAccount.client_email,
              aud: "https://oauth2.googleapis.com/token",
              iat: getNumericDate(0),
              exp: getNumericDate(3600),
              scope: "https://www.googleapis.com/auth/firebase.messaging",
            },
            key
          );

          const response = await fetch("https://oauth2.googleapis.com/token", {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: new URLSearchParams({
              grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
              assertion: jwt,
            }),
          });

          const tokenJson = await response.json();
          const access_token = tokenJson.access_token;

          if (access_token) {
            await fetch(
              `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
              {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  Authorization: `Bearer ${access_token}`,
                },
                body: JSON.stringify({
                  message: {
                    token: tokenData.fcm_token,
                    notification: {
                      title: "Ride Allotted! 🚕",
                      body: `Quote received for your ride. Trip Price: INR ${price}`,
                    },
                    data: {
                      type: "allotment",
                      trip_id: trip_id,
                    },
                    android: {
                      priority: "high",
                      notification: {
                        sound: "default",
                        channel_id: "trip_updates",
                      },
                    },
                  },
                }),
              }
            );
          }
        }
      } catch (fcmError) {
        console.error("Failed to send FCM notification:", fcmError);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Trip allotted and V1 notification sent.",
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
