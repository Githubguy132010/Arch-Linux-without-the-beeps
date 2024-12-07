import Link from 'next/link'
import { Download } from 'lucide-react'

export default function DownloadPage() {
  return (
    <div className="container mx-auto px-4 py-16 animate-fade-in">
      <h1 className="text-4xl md:text-5xl font-bold text-center mb-8 text-gray-800 dark:text-white">
        Download Arch Linux without Beeps
      </h1>
      <div className="max-w-2xl mx-auto bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
        <p className="text-lg mb-6 text-gray-600 dark:text-gray-300">
          Get the latest version of Arch Linux installation files without the annoying system beeps. Our custom ISO ensures a smooth and quiet installation process.
        </p>
        <div className="flex justify-center">
          <Link 
            href="https://github.com/Githubguy132010/Arch-Linux-without-the-beeps/releases"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center bg-primary text-primary-foreground hover:bg-primary/90 px-6 py-3 rounded-md text-lg font-semibold transition-colors"
          >
            <Download className="mr-2" size={24} />
            Download Latest Release
          </Link>
        </div>
        <div className="mt-8 text-sm text-gray-500 dark:text-gray-400">
          <h2 className="font-semibold mb-2">System Requirements:</h2>
          <ul className="list-disc list-inside">
            <li>x86_64 architecture</li>
            <li>Minimum 512 MB RAM (2 GB recommended)</li>
            <li>Minimum 2 GB disk space (20 GB recommended)</li>
            <li>Internet connection for installation</li>
          </ul>
        </div>
      </div>
    </div>
  )
}

