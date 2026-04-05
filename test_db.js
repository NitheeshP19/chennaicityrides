const supabaseUrl = 'https://dycanquxbnecrritcoou.supabase.co';
const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5Y2FucXV4Ym5lY3JyaXRjb291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwMjc1MzEsImV4cCI6MjA5MDYwMzUzMX0.i85iLktslLTHZAF3V0xn8_5FKLwqUXqQP6eAai9rSyk';

async function checkDatabase() {
  const fetchResponse = await fetch(`${supabaseUrl}/rest/v1/trip_requests`, {
    headers: {
      'apikey': anonKey,
      'Authorization': `Bearer ${anonKey}`
    }
  });

  const trips = await fetchResponse.json();
  console.log("All trips:");
  for (let t of trips) {
    if(t.pickup_location === 'test' && t.dropoff_location === 'test') {
      console.log(`${t.id} - ${t.pickup_location} -> ${t.dropoff_location}: ${t.status}`);
    }
  }
}

checkDatabase();
