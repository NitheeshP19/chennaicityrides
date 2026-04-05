async function testEdgeFunction() {
  const supabaseUrl = 'https://dycanquxbnecrritcoou.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5Y2FucXV4Ym5lY3JyaXRjb291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwMjc1MzEsImV4cCI6MjA5MDYwMzUzMX0.i85iLktslLTHZAF3V0xn8_5FKLwqUXqQP6eAai9rSyk';

  console.log("Fetching a trip to test with...");
  const fetchResponse = await fetch(`${supabaseUrl}/rest/v1/trip_requests?select=id&limit=1`, {
    headers: {
      'apikey': anonKey,
      'Authorization': `Bearer ${anonKey}`
    }
  });

  const trips = await fetchResponse.json();
  const validTripId = trips[0].id;
  console.log("Using trip_id:", validTripId);

  console.log("Invoking edge function allot-trip...");
  const edgeResponse = await fetch(`${supabaseUrl}/functions/v1/allot-trip`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${anonKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      trip_id: validTripId,
      driver_name: "Test Driver",
      driver_phone: "9876543210",
      vehicle_type: "Sedan",
      price: 1500
    })
  });

  console.log("Status:", edgeResponse.status);
  const text = await edgeResponse.text();
  console.log("Response:", text);
}

testEdgeFunction();
