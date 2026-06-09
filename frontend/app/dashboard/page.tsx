export default function DashboardPage() {

  return (

    <div className="p-8">

      <h1 className="text-4xl font-bold mb-8">
        Dashboard
      </h1>

      <div className="grid grid-cols-3 gap-6">

        <div className="border rounded-xl p-6">
          Active Escrows
        </div>

        <div className="border rounded-xl p-6">
          Completed Jobs
        </div>

        <div className="border rounded-xl p-6">
          Total Volume
        </div>

      </div>

    </div>
  );
}