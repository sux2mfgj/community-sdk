/****************************************************************************
**
** Copyright 2015 by Emotiv. All rights reserved
** Example - ActivateLicense
** How to activate a license key
 ***
****************************************************************************/

using System;
using System.Collections.Generic;
using Emotiv;
using System.IO;
using System.Threading;
using System.Reflection;

namespace ActivateLicense
{
    class ActivateLicense
    {
        static string licenseKey = "";           // Your License Key

        static string format = "dd/MM/yyyy";
        static Int32 debitNum = 0; //example 
        static int userCloudID = 0;
        static string userName = "";
        static string password = "";

        static void activateLicense()
        {
            Console.Write("\nPlease enter of NUMBER OF DEBITS :");
            debitNum = Convert.ToInt32(Console.ReadLine());
            
            int result = EdkDll.IEE_AuthorizeLicense(licenseKey, debitNum);
            if (result == EdkDll.EDK_OK || result == EdkDll.EDK_LICENSE_REGISTERED)
            {
                //Console.WriteLine("Active/Debit successfully.");
            }
            else Console.WriteLine("Active/Debit unsuccessfully. Errorcode : " + result);
        }

        static public DateTime FromUnixTime(uint unixTime)
        {
            var epoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            return epoch.AddSeconds(unixTime);
        }

        static public long ToUnixTime(DateTime date)
        {
            var epoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            return Convert.ToInt64((date - epoch).TotalSeconds);
        }

        static void getDebitInformation()
        {
            EdkDll.IEE_DebitInfos_t debitInfos = new EdkDll.IEE_DebitInfos_t();
            int result = EdkDll.IEE_GetDebitInformation(licenseKey, ref debitInfos);
            if(debitInfos.total_session_inYear > 0)
            {
                Console.WriteLine();
                Console.WriteLine("Remain Sessions                      : " + debitInfos.remainingSessions);
                Console.WriteLine("Total debitable sessions in Year     : " + debitInfos.total_session_inYear);
                Console.WriteLine();
            }
            else if(debitInfos.total_session_inMonth > 0)
            {
                Console.WriteLine();
                Console.WriteLine("Remain Sessions                      : " + debitInfos.remainingSessions);
                Console.WriteLine("Total debitable sessions in Month    : " + debitInfos.total_session_inMonth);
                Console.WriteLine();
            }
            else
            {
                Console.WriteLine();
                Console.WriteLine("Remain Sessions                      : unlimitted");
                Console.WriteLine("Total debitable sessions in Year     : unlimitted");
                Console.WriteLine();
            }
        }

        static void licenseInformation()
        {
            Console.WriteLine("Get License Information");
            Console.WriteLine();

            EdkDll.IEE_LicenseInfos_t licenseInfos = new EdkDll.IEE_LicenseInfos_t();
            int result = EdkDll.IEE_LicenseInformation(ref licenseInfos);
            if(result == EdkDll.EDK_OK)
            {
                Console.WriteLine("Active/Debit successfully.");//Activate/Debit actually successfully when get license information without error

                Console.WriteLine();
                Console.WriteLine("Date From                : " + FromUnixTime(licenseInfos.date_from).ToString(format));
                Console.WriteLine("Date To                  : " + FromUnixTime(licenseInfos.date_to).ToString(format));
                Console.WriteLine();

                Console.WriteLine();
                Console.WriteLine("Grace Period       from  " + FromUnixTime(licenseInfos.soft_limit_date).ToString(format) + "     to    " +
                                                                    FromUnixTime(licenseInfos.hard_limit_date).ToString(format));
                Console.WriteLine();

                Console.WriteLine("Number of seats          : " + licenseInfos.seat_count);
                Console.WriteLine();

                Console.WriteLine("Total Quotas             : " + licenseInfos.quota);
                Console.WriteLine("Total quotas used        : " + licenseInfos.usedQuota);
                Console.WriteLine();

                switch ((int)licenseInfos.scopes)
                {
                    case (int)EdkDll.IEE_LicenseType_t.IEE_EEG:

                        Console.WriteLine("License type : EEG");
                        Console.WriteLine();
                        break;
                    case (int)EdkDll.IEE_LicenseType_t.IEE_EEG_PM:

                        Console.WriteLine("License type : EEG + PM");
                        Console.WriteLine();
                        break;
                    case (int)EdkDll.IEE_LicenseType_t.IEE_PM:
                        Console.WriteLine("License type : PM");
                        Console.WriteLine();
                        break;
                    default:
                        Console.WriteLine("License type : No type");
                        Console.WriteLine();
                        break;
                }
            }
            else
            {
                switch(result)
                {
                    case EdkDll.EDK_LICENSE_EXPIRED:
                        Console.WriteLine("The license has expired");
                        Console.WriteLine();
                        Console.WriteLine("From Date                : " + FromUnixTime(licenseInfos.date_from).ToString(format));
                        Console.WriteLine("To Date                  : " + FromUnixTime(licenseInfos.date_to).ToString(format));
                        Console.WriteLine();
                        break;
                    case EdkDll.EDK_LICENSE_DEVICE_LIMITED:
                        Console.WriteLine("Device limited");
                        Console.WriteLine();
                        break;
                    case EdkDll.EDK_OVER_QUOTA:
                        Console.WriteLine("Device limited");
                        Console.WriteLine();
                        break;
                    case EdkDll.EDK_NO_ACTIVE_LICENSE:
                        Console.WriteLine("No active license");
                        Console.WriteLine();
                        break;
                    case EdkDll.EDK_LICENSE_ERROR:
                        Console.WriteLine("The license is error");
                        Console.WriteLine();
                        break;
                    default:
                        Console.WriteLine("Unknown Error with Errorcode: " + result);
                        Console.WriteLine();
                        break;
                }
                Console.WriteLine();
                
            }

        }

        static void Main(string[] args)
        {
            Console.WriteLine("===========================================");
            Console.WriteLine("The example to activate a license key.");
            Console.WriteLine("===========================================");
            
            EmoEngine engine = EmoEngine.Instance;
            engine.Connect();

            //Authorize
            if (EmotivCloudClient.EC_Connect() != EdkDll.EDK_OK)
            {
                Console.WriteLine("Cannot connect to Emotiv Cloud.");
                Thread.Sleep(2000);
                return;
            }

            if (EmotivCloudClient.EC_Login(userName, password) != EdkDll.EDK_OK)
            {
                Console.WriteLine("Your login attempt has failed. The username or password may be incorrect");
                Thread.Sleep(2000);
                return;
            }

            Console.WriteLine("Logged in as " + userName);

            if (EmotivCloudClient.EC_GetUserDetail(ref userCloudID) != EdkDll.EDK_OK)
                return;

            //GetDebitInfo
            getDebitInformation();

            //Active license
            activateLicense();

            //We can call this API any time to check current License information
            licenseInformation();

            Thread.Sleep(5000);
        }
    }
}
