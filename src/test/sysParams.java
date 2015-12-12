import java.io.*;
import java.net.*;
import java.util.*;
import java.lang.*;

class sysParams {
    public static void main(String[] args) {
		System.out.println("PRORERTIES");
		Properties sysParams = System.getProperties();
        for(Object e : sysParams.entrySet()) {
            System.out.println(e);
        }

		System.out.println("\nENVIROMENT");
		Map<String, String> sysEnv = System.getenv();
		for(String env : sysEnv.keySet()) {
            System.out.println(env + " : " + sysEnv.get(env));
        }

		try {
			// wmic command for diskdrive id: wmic DISKDRIVE GET SerialNumber
			// wmic command for cpu id : wmic cpu get ProcessorId
			//Process process = Runtime.getRuntime().exec(new String[] {"wmic", "bios", "get", "serialnumber" });
			//Process process = Runtime.getRuntime().exec(new String[] {"wmic", "csproduct", "get", "vendor,name,identifyingnumber"});
			Process process = Runtime.getRuntime().exec(new String[] {"wmic", "bios", "get", "serialnumber" });
			process.getOutputStream().close();
			Scanner sc = new Scanner(process.getInputStream());
			System.out.println("\nSERIALS");
			
			while (sc.hasNext()) {
				String property = sc.next();
				System.out.println(property);
			}
		} catch(IOException ex) {
			System.out.println("IO Error : " + ex);
		}

		System.out.println("\nNETWORK");
		try {
			Enumeration<NetworkInterface> nets = NetworkInterface.getNetworkInterfaces();
			for (NetworkInterface netint : Collections.list(nets)) {
				String bStr = conv(netint.getHardwareAddress());
				System.out.println("Display name: " + netint.getDisplayName());
				System.out.println("Name: " + netint.getName());
				System.out.println("MAC: " + bStr);
				Enumeration<InetAddress> inetAddresses = netint.getInetAddresses();
				for (InetAddress inetAddress : Collections.list(inetAddresses)) {
					System.out.println("InetAddress: " + inetAddress);
				}
				System.out.println("\n");
			}
		} catch(SocketException ex) {
			System.out.println("Inteface Error : " + ex);
		}

	}

	public static String conv(byte[] netBytes) {
		StringBuilder sb = new StringBuilder();
		if(netBytes == null) return "";
		for (byte b : netBytes)
			sb.append(String.format("%02X ", b));
		return sb.toString();
    }
}

