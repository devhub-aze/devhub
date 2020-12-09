<?php

namespace Database\Seeders;

use App\Models\Article;
use App\Models\User;
use Carbon\Carbon;
use Hash;
use Illuminate\Database\Seeder;

class UserTableSeeder extends Seeder
{
    public function run()
    {
        $user = User::create([
            'username'   => config('devhub.admin_name'),
            'email'      => config('devhub.admin_email'),
            'password'   => Hash::make(config('devhub.admin_password')),
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now(),
        ]);
        User::factory()
            ->count(30)
            ->has(
                Article::factory()
                    ->count(3)
            )->create();
    }
}
