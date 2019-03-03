using System;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;

namespace FiSSH_Windows
{
    class Program
    {
        static void Main(string[] args)
        {
            TextWriter Error = Console.Error;
            try
            {
                // Locate FiSSH certificate
                X509Certificate2 fissh_cert = null;
                X509Store x509Store = new X509Store(StoreName.My, StoreLocation.CurrentUser);
                x509Store.Open(OpenFlags.ReadOnly);

                foreach (X509Certificate2 x509Certificate in x509Store.Certificates)
                {
                    if (x509Certificate.Subject.Contains("CN=FiSSH"))
                    {
                        fissh_cert = x509Certificate;
                        Error.WriteLine("FiSSH Certificate Loaded!");
                        break;
                    }
                }

                if (fissh_cert == null) throw new Exception("Unable to find FiSSH certificate");
                if (!fissh_cert.HasPrivateKey) throw new Exception("Unable to load FiSSH private key");

                TcpListener tcpListener = new TcpListener(IPAddress.Any, 2222);
                tcpListener.Start();
                Error.WriteLine("Please authorize the SSH connection using the FiSSH app on your phone.");
                TcpClient tcpClient = tcpListener.AcceptTcpClient();
                SslStream sslStream = new SslStream(tcpClient.GetStream());
                
                IAsyncResult secureConnect = sslStream.BeginAuthenticateAsServer(fissh_cert, false, System.Security.Authentication.SslProtocols.Tls | System.Security.Authentication.SslProtocols.Tls11 | System.Security.Authentication.SslProtocols.Tls12, false, null, null);
                
                if (!secureConnect.AsyncWaitHandle.WaitOne(TimeSpan.FromSeconds(5), false))
                {
                    sslStream.Close();
                    throw new Exception("Handshake failed due to timeout.\n\nNOTE: If you are prompted on your phone to approve the certificate, then this error is NORMAL, verify the certificate fingerprint as instructed and run FiSSH on your PC again after approving the certificate.\n\n");
                }

                sslStream.EndAuthenticateAsServer(secureConnect);

                StreamReader streamReader = new StreamReader(sslStream);
                Error.WriteLine("Authorization received. Relaying authorization to OpenSSH.");
                Console.WriteLine(streamReader.ReadLine());
                sslStream.Close();
                tcpListener.Stop();
            }
            catch (Exception ex)
            {
                Error.WriteLine("Error: " + ex.Message);
            }
        }
    }
}
