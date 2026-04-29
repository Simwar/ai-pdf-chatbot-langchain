import { createServerClient } from '@/lib/langgraph-server';
import { NextResponse } from 'next/server';

export async function POST() {
  try {
    const serverClient = createServerClient();
    const thread = await serverClient.client.threads.create();
    return NextResponse.json(thread);
  } catch (error) {
    console.error('Error creating thread:', error);
    return NextResponse.json(
      { error: 'Failed to create thread' },
      { status: 500 },
    );
  }
}
