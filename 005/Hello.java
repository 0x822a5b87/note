class Hello
{
	private static void loop()
	{
		for (int i = 0; i < 10; ++i)
		{
			System.out.println("Hello world");
			try
			{
				Thread.sleep(1000);
			}
			catch(Exception e)
			{

			}
		}
	}

	public static void main(String[] args)
	{
		while (true)
		{
			loop();
		}
	}
}
