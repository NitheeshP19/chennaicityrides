async function testCors() {
  const supabaseUrl = 'https://dycanquxbnecrritcoou.supabase.co';

  console.log("Testing OPTIONS preflight...");
  const edgeResponse = await fetch(`${supabaseUrl}/functions/v1/allot-trip`, {
    method: 'OPTIONS',
    headers: {
      'Origin': 'https://chennaicityrides-k7kd.vercel.app',
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'authorization, content-type, apikey, x-client-info'
    }
  });

  console.log("Status:", edgeResponse.status);
  console.log("Headers:");
  edgeResponse.headers.forEach((val, key) => {
    console.log(`  ${key}: ${val}`);
  });
  const text = await edgeResponse.text();
  console.log("Response body:", text);
}

testCors();
