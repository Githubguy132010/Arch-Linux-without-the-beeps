import Link from 'next/link'

export default function DocsPage() {
  return (
    <div className="container mx-auto px-4 py-16 animate-fade-in">
      <h1 className="text-4xl md:text-5xl font-bold text-center mb-8 text-gray-800 dark:text-white">
        Documentation
      </h1>
      <div className="max-w-3xl mx-auto bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
        <h2 className="text-2xl font-bold mb-4 text-gray-800 dark:text-white">Installation Guide</h2>
        <ol className="list-decimal list-inside space-y-4 text-gray-600 dark:text-gray-300">
          <li>
            <span className="font-semibold">Download the ISO:</span> Get the latest Arch Linux without Beeps ISO from our{' '}
            <Link href="/download" className="text-primary hover:underline">download page</Link>.
          </li>
          <li>
            <span className="font-semibold">Create a bootable USB drive:</span> Use a tool like Rufus or dd to create a bootable USB drive with the downloaded ISO.
          </li>
          <li>
            <span className="font-semibold">Boot from the USB drive:</span> Restart your computer and boot from the USB drive. You may need to change your BIOS/UEFI settings to do this.
          </li>
          <li>
            <span className="font-semibold">Follow the Arch Linux installation guide:</span> Our ISO follows the standard Arch Linux installation process, but without the system beeps. Refer to the{' '}
            <a href="https://wiki.archlinux.org/title/Installation_guide" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">
              official Arch Linux installation guide
            </a>{' '}
            for detailed steps.
          </li>
          <li>
            <span className="font-semibold">Enjoy your beep-free Arch Linux:</span> Once installed, you'll have a fully functional Arch Linux system without the annoying beeps during boot or system events.
          </li>
        </ol>
        <h2 className="text-2xl font-bold mt-8 mb-4 text-gray-800 dark:text-white">Troubleshooting</h2>
        <p className="mb-4 text-gray-600 dark:text-gray-300">
          If you encounter any issues during installation or have questions, please check our{' '}
          <a href="https://github.com/Githubguy132010/Arch-Linux-without-the-beeps/issues" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">
            GitHub Issues
          </a>{' '}
          page or create a new issue for support.
        </p>
      </div>
    </div>
  )
}

