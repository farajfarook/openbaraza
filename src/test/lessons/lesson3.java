public class lesson3 {

	int x = 0;
	int y = 0;
	int z = 0;

	public int add(String lx, String ly) {
		x = Integer.valueOf(lx);
		y = Integer.valueOf(ly);
		z = x + y;
                return z;
        }

	public int add(int lx, int ly) {
		x = lx;
		y = ly;
		z = x + y;
		return z;
	}

	public int sub(String lx, String ly) {
		x = Integer.valueOf(lx);
		y = Integer.valueOf(ly);
		z = x - y;
		return z;
	}

	public int sub(int lx, int ly) {
		x = lx;
		y = ly;
		z = x - y;
		return z;
	}

	public int multiply(String lx, String ly) {
		x = Integer.valueOf(lx);
		y = Integer.valueOf(ly);
		z = x * y;
		return z;
	}

	public int multiply(int lx, int ly) {
		x = lx;
		y = ly; 
		z = x * y;
		return z;
	}

	public boolean check(String lz) {
		int z = Integer.valueOf(lz);
		return check(z);
	}

	public boolean check(int lz) {
		boolean ans = false;

		if(z == lz) ans = true;
		else ans = false;

		return ans;
	}

}
